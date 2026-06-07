"""Lightweight factory for image generation providers.

No registry, no descriptors, no catalog. Reads settings and returns the right
provider. Deliberately separate from the chat provider machinery.
"""

from __future__ import annotations

import httpx

from config.settings import Settings
from providers.exceptions import InvalidRequestError

from .base import ImageGenProvider


def create_image_gen_provider(
    settings: Settings,
    http_client: httpx.AsyncClient | None = None,
) -> ImageGenProvider:
    """Return the configured image generation provider.

    Reads ``IMAGE_GEN_PROVIDER`` (default ``"fal"``) and the corresponding
    API key (``FAL_KEY`` or ``IMAGE_GEN_GOOGLE_API_KEY``).
    """
    provider_key = settings.image_gen_provider

    if provider_key == "google":
        return _create_google(settings, http_client)

    if not settings.fal_key:
        raise InvalidRequestError(
            "FAL_KEY is not set. Add it to your .env file. "
            "Get a key at https://fal.ai/dashboard"
        )

    from .fal_client import FalImageGenProvider

    return FalImageGenProvider(
        api_key=settings.fal_key,
        http_client=http_client,
    )


def _create_google(
    settings: Settings,
    http_client: httpx.AsyncClient | None,
) -> ImageGenProvider:
    if not settings.image_gen_google_api_key:
        raise InvalidRequestError(
            "IMAGE_GEN_GOOGLE_API_KEY is not set. "
            "Set it or switch IMAGE_GEN_PROVIDER to 'fal'."
        )

    from .google_client import GoogleImageGenDispatcher

    return GoogleImageGenDispatcher(
        api_key=settings.image_gen_google_api_key,
        http_client=http_client,
    )
