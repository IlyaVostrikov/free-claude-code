"""Google image generation providers.

Two separate APIs under one roof:

* **Nano Banana** (generateContent) — multimodal models that output images:
  ``gemini-3-pro-image``, ``gemini-3.1-flash-image``, ``gemini-2.5-flash-image``
* **Imagen** (:predict) — dedicated text-to-image models:
  ``imagen-4.0-ultra-generate-001``, ``imagen-4.0-generate-001``, ``imagen-4.0-fast-generate-001``

API docs:
  Nano Banana — https://ai.google.dev/gemini-api/docs/image-generation
  Imagen      — https://ai.google.dev/gemini-api/docs/imagen
"""

from __future__ import annotations

import time
from typing import Any

import httpx
from loguru import logger

from providers.exceptions import (
    APIError,
    AuthenticationError,
    InvalidRequestError,
    OverloadedError,
    RateLimitError,
)

from .base import GeneratedImage, ImageGenProvider, ImageGenRequest, ImageGenResponse

# ============================================================================
# Model constants — ranked by quality (best → fastest)
# ============================================================================

# --- Imagen (dedicated text-to-image, :predict API) ---
IMAGEN_4_ULTRA = "imagen-4.0-ultra-generate-001"  # highest quality, 1K/2K
IMAGEN_4 = "imagen-4.0-generate-001"               # standard quality, 1K/2K
IMAGEN_4_FAST = "imagen-4.0-fast-generate-001"     # speed-optimized, 1K only

IMAGEN_MODELS = {IMAGEN_4_ULTRA, IMAGEN_4, IMAGEN_4_FAST}

# --- Nano Banana Pro (generateContent API) ---
NANO_BANANA_PRO = "gemini-3-pro-image"             # professional quality, 1K/2K/4K

# --- Nano Banana 2 (generateContent API) ---
NANO_BANANA_2 = "gemini-3.1-flash-image"           # high-efficiency, 512/1K/2K/4K

# --- Nano Banana (generateContent API) ---
NANO_BANANA = "gemini-2.5-flash-image"             # speed-oriented, stable

NANO_BANANA_MODELS = {
    "gemini-3-pro-image",
    "gemini-3-pro-image-preview",
    "nano-banana-pro-preview",
    "gemini-3.1-flash-image",
    "gemini-3.1-flash-image-preview",
    "gemini-2.5-flash-image",
}

DEFAULT_MODEL = NANO_BANANA_2

# ============================================================================
# Shared Google API endpoints
# ============================================================================
GEMINI_API_BASE = "https://generativelanguage.googleapis.com/v1beta"


def _pick_provider_class(model: str) -> type[ImageGenProvider]:
    """Route model name to the correct provider class."""
    if any(model.startswith(prefix) for prefix in ("imagen",)):
        return ImagenImageGenProvider
    return NanoBananaProvider


def create_google_provider(
    api_key: str,
    model: str = DEFAULT_MODEL,
    http_client: httpx.AsyncClient | None = None,
) -> ImageGenProvider:
    """Return the right Google provider for the requested model."""
    cls = _pick_provider_class(model)
    return cls(api_key=api_key, http_client=http_client, model=model)


# ============================================================================
# Google dispatcher — single entry point, routes by model
# ============================================================================

class GoogleImageGenDispatcher(ImageGenProvider):
    """Entry point for all Google image gen models.

    Routes each request to the correct provider (NanoBananaProvider or
    ImagenImageGenProvider) based on the model name in the request.
    """

    def __init__(
        self,
        api_key: str,
        http_client: httpx.AsyncClient | None = None,
    ):
        self._api_key = api_key
        self._client = http_client
        self._owns_client = http_client is None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is not None:
            return self._client
        self._client = httpx.AsyncClient(
            timeout=httpx.Timeout(180.0, connect=15.0),
        )
        return self._client

    async def generate(self, request: ImageGenRequest) -> ImageGenResponse:
        client = await self._get_client()
        model = request.model or DEFAULT_MODEL

        provider = _pick_provider_class(model)(
            api_key=self._api_key,
            http_client=client,
            model=model,
        )
        return await provider.generate(request)

    async def cleanup(self) -> None:
        if self._owns_client and self._client is not None:
            await self._client.aclose()
            self._client = None


# ============================================================================
# Nano Banana provider (generateContent API)
# ============================================================================

class NanoBananaProvider(ImageGenProvider):
    """Image generation via Gemini multimodal models (generateContent API).

    Supports: Nano Banana Pro, Nano Banana 2, Nano Banana.
    """

    _SIZE_MAP: dict[str, str] = {
        "1024x1024": "1K",
        "2048x2048": "2K",
        "4096x4096": "4K",
        "1K": "1K",
        "2K": "2K",
        "4K": "4K",
    }

    _ASPECT_MAP: dict[str, str] = {
        "1024x1024": "1:1",
        "1792x1024": "16:9",
        "1024x1792": "9:16",
        "1280x1024": "4:3",
        "1024x1280": "3:4",
        "2880x2048": "3:2",
        "2048x2880": "2:3",
    }

    def __init__(
        self,
        api_key: str,
        http_client: httpx.AsyncClient | None = None,
        model: str = DEFAULT_MODEL,
    ):
        self._api_key = api_key
        self._client = http_client
        self._owns_client = http_client is None
        self._model = model

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is not None:
            return self._client
        self._client = httpx.AsyncClient(
            timeout=httpx.Timeout(180.0, connect=15.0),
        )
        return self._client

    async def generate(self, request: ImageGenRequest) -> ImageGenResponse:
        client = await self._get_client()
        model = request.model or self._model

        url = f"{GEMINI_API_BASE}/models/{model}:generateContent?key={self._api_key}"

        gen_config: dict[str, Any] = {"responseModalities": ["IMAGE", "TEXT"]}

        image_size = self._SIZE_MAP.get(request.size, "1K")
        aspect_ratio = self._ASPECT_MAP.get(request.size, "1:1")

        # 3 Pro has mandatory thinking; 3.1 Flash has optional thinking levels
        if "3-pro" in model or "banana-pro" in model:
            gen_config["thinkingConfig"] = {"thinkingBudget": 0}
        elif "3.1" in model or "banana-2" in model:
            gen_config["thinkingConfig"] = {"thinkingLevel": "high"}

        payload: dict[str, Any] = {
            "contents": [{"parts": [{"text": request.prompt}]}],
            "generationConfig": gen_config,
            "imageGenerationConfig": {
                "imageSize": image_size,
                "aspectRatio": aspect_ratio,
            },
        }

        try:
            resp = await client.post(url, json=payload)
            resp.raise_for_status()
            result = resp.json()
        except httpx.HTTPStatusError as e:
            _raise_mapped_error(e)

        return _parse_gemini_response(result, request.normalized_response_format())

    async def cleanup(self) -> None:
        if self._owns_client and self._client is not None:
            await self._client.aclose()
            self._client = None


# ============================================================================
# Imagen provider (:predict API)
# ============================================================================

class ImagenImageGenProvider(ImageGenProvider):
    """Image generation via Imagen 4 (dedicated text-to-image).

    Uses the :predict endpoint with x-goog-api-key header auth.
    Supports: Imagen 4 Ultra, Imagen 4, Imagen 4 Fast.
    """

    _SIZE_MAP: dict[str, str] = {
        "1024x1024": "1K",
        "1792x1024": "2K",
        "2048x2048": "2K",
        "2880x2048": "2K",
        "1K": "1K",
        "2K": "2K",
    }

    _ASPECT_MAP: dict[str, str] = {
        "1024x1024": "1:1",
        "1792x1024": "16:9",
        "1024x1792": "9:16",
        "1280x1024": "4:3",
        "1024x1280": "3:4",
        "2880x2048": "3:2",
        "2048x2880": "2:3",
    }

    def __init__(
        self,
        api_key: str,
        http_client: httpx.AsyncClient | None = None,
        model: str = IMAGEN_4,
    ):
        self._api_key = api_key
        self._client = http_client
        self._owns_client = http_client is None
        self._model = model

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is not None:
            return self._client
        self._client = httpx.AsyncClient(
            timeout=httpx.Timeout(180.0, connect=15.0),
        )
        return self._client

    async def generate(self, request: ImageGenRequest) -> ImageGenResponse:
        client = await self._get_client()
        model = request.model or self._model

        url = f"{GEMINI_API_BASE}/models/{model}:predict"

        image_size = self._SIZE_MAP.get(request.size, "1K")
        aspect_ratio = self._ASPECT_MAP.get(request.size, "1:1")

        # Fast model only supports 1K
        if "fast" in model:
            image_size = "1K"

        payload: dict[str, Any] = {
            "instances": [{"prompt": request.prompt}],
            "parameters": {
                "sampleCount": request.n,
                "sampleImageSize": image_size,
                "aspectRatio": aspect_ratio,
            },
        }

        logger.info(f"Imagen request: model={model} size={request.size} -> "
                    f"sampleImageSize={image_size} aspectRatio={aspect_ratio}")

        headers = {"x-goog-api-key": self._api_key}

        try:
            resp = await client.post(url, json=payload, headers=headers)
            resp.raise_for_status()
            result = resp.json()
        except httpx.HTTPStatusError as e:
            _raise_mapped_error(e)

        return _parse_imagen_response(result, request.normalized_response_format())

    async def cleanup(self) -> None:
        if self._owns_client and self._client is not None:
            await self._client.aclose()
            self._client = None


# ============================================================================
# Response parsers
# ============================================================================

def _parse_gemini_response(
    result: dict[str, Any], response_format: str
) -> ImageGenResponse:
    """Extract images from Nano Banana generateContent response."""
    images: list[GeneratedImage] = []

    for candidate in result.get("candidates", []):
        for part in candidate.get("content", {}).get("parts", []):
            if "inlineData" not in part:
                continue
            inline = part["inlineData"]
            b64_data = inline.get("data", "")
            mime = inline.get("mimeType", "image/png")

            if response_format == "b64_json":
                images.append(GeneratedImage(b64_json=b64_data))
            else:
                images.append(GeneratedImage(url=f"data:{mime};base64,{b64_data}"))

    return ImageGenResponse(created=int(time.time()), data=images)


def _parse_imagen_response(
    result: dict[str, Any], response_format: str
) -> ImageGenResponse:
    """Extract images from Imagen :predict response."""
    images: list[GeneratedImage] = []

    for prediction in result.get("predictions", []):
        b64_data = prediction.get("bytesBase64Encoded", "")
        mime = prediction.get("mimeType", "image/png")

        if not b64_data:
            continue

        if response_format == "b64_json":
            images.append(GeneratedImage(b64_json=b64_data))
        else:
            images.append(GeneratedImage(url=f"data:{mime};base64,{b64_data}"))

    return ImageGenResponse(created=int(time.time()), data=images)


# ============================================================================
# Error mapping
# ============================================================================

def _raise_mapped_error(exc: httpx.HTTPStatusError) -> None:
    status = exc.response.status_code
    detail = _safe_text(exc)
    if status in (401, 403):
        raise AuthenticationError(detail) from exc
    if status == 429:
        raise RateLimitError(detail) from exc
    if status == 400:
        raise InvalidRequestError(detail) from exc
    if status in (502, 503, 504):
        raise OverloadedError(detail) from exc
    raise APIError(detail, status_code=status) from exc


def _safe_text(exc: httpx.HTTPStatusError) -> str:
    try:
        return exc.response.text[:1024]
    except Exception:
        return f"HTTP {exc.response.status_code}"
