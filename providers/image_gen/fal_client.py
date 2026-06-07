"""fal.ai image generation provider (Nano Banana 2 / Gemini 3.1 Flash Image)."""

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

FAL_NANO_BANANA_MODEL = "fal-ai/nano-banana-2"

_SIZE_MAP: dict[str, dict[str, Any]] = {
    "1024x1024": {"image_size": "square_hd"},
    "1792x1024": {"image_size": "landscape_16_9"},
    "1024x1792": {"image_size": "portrait_16_9"},
    "1344x768": {"image_size": "landscape_4_3"},
    "768x1344": {"image_size": "portrait_4_3"},
    "768x768": {"image_size": "square"},
}


def _map_openai_size_to_fal(size: str) -> dict[str, Any]:
    key = size.strip()
    if key in _SIZE_MAP:
        return dict(_SIZE_MAP[key])
    logger.warning("Unknown image size '{}', falling back to square_hd", size)
    return {"image_size": "square_hd"}


class FalImageGenProvider(ImageGenProvider):
    """Image generation via fal.ai REST API (Nano Banana 2)."""

    def __init__(
        self,
        api_key: str,
        http_client: httpx.AsyncClient | None = None,
        base_url: str = "https://fal.run",
    ):
        self._api_key = api_key
        self._client = http_client
        self._base_url = base_url.rstrip("/")
        self._owns_client = http_client is None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is not None:
            return self._client
        self._client = httpx.AsyncClient(
            headers={"Authorization": f"Key {self._api_key}"},
            timeout=httpx.Timeout(120.0, connect=10.0),
        )
        return self._client

    async def generate(self, request: ImageGenRequest) -> ImageGenResponse:
        client = await self._get_client()

        size_params = _map_openai_size_to_fal(request.size)

        payload: dict[str, Any] = {
            "prompt": request.prompt,
            "num_images": request.normalized_n(),
            **size_params,
        }

        url = f"{self._base_url}/{FAL_NANO_BANANA_MODEL}"

        try:
            resp = await client.post(url, json=payload)
            resp.raise_for_status()
            result = resp.json()
        except httpx.HTTPStatusError as e:
            self._raise_mapped_error(e)

        return _parse_fal_response(result, request.normalized_response_format())

    async def cleanup(self) -> None:
        if self._owns_client and self._client is not None:
            await self._client.aclose()
            self._client = None

    def _raise_mapped_error(self, exc: httpx.HTTPStatusError) -> None:
        status = exc.response.status_code
        detail = _safe_response_text(exc)
        if status in (401, 403):
            raise AuthenticationError(detail) from exc
        if status == 429:
            raise RateLimitError(detail) from exc
        if status == 400:
            raise InvalidRequestError(detail) from exc
        if status in (502, 503, 504):
            raise OverloadedError(detail) from exc
        raise APIError(detail, status_code=status) from exc


def _safe_response_text(exc: httpx.HTTPStatusError) -> str:
    try:
        return exc.response.text[:1024]
    except Exception:
        return f"HTTP {exc.response.status_code}"


def _parse_fal_response(
    result: dict[str, Any], response_format: str
) -> ImageGenResponse:
    images_data: list[GeneratedImage] = []

    raw_images = result.get("images", [])
    for img in raw_images:
        images_data.append(
            GeneratedImage(
                url=img.get("url") if response_format == "url" else None,
                b64_json=None,
            )
        )

    return ImageGenResponse(created=int(time.time()), data=images_data)
