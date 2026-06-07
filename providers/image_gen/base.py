"""Abstract base for image generation providers and shared models."""

from __future__ import annotations

from abc import ABC, abstractmethod

from pydantic import BaseModel, ConfigDict, Field


class GeneratedImage(BaseModel):
    """A single generated image result (OpenAI-compatible)."""

    url: str | None = None
    b64_json: str | None = None
    revised_prompt: str | None = None


class ImageGenResponse(BaseModel):
    """OpenAI-compatible images/generations response."""

    created: int
    data: list[GeneratedImage]


class ImageGenRequest(BaseModel):
    """OpenAI-compatible images/generations request body.

    Extra fields are allowed so provider-specific parameters (e.g. fal.ai
    ``image_size``, ``num_images``) can pass through without validation errors.
    """

    model_config = ConfigDict(extra="allow")

    prompt: str = Field(..., min_length=1, max_length=4000)
    model: str = "nano-banana-2"
    n: int = Field(default=1, ge=1, le=10)
    size: str = "1024x1024"
    response_format: str = "url"

    def normalized_response_format(self) -> str:
        fmt = self.response_format.lower()
        return fmt if fmt in ("url", "b64_json") else "url"

    def normalized_n(self) -> int:
        return max(1, min(self.n, 10))


class ImageGenProvider(ABC):
    """Abstract image generation provider.

    Deliberately separate from ``BaseProvider`` — no streaming, no SSE, no
    thinking, no model listing. Simple request → response.
    """

    @abstractmethod
    async def generate(self, request: ImageGenRequest) -> ImageGenResponse:
        """Generate images and return an OpenAI-format response."""
        ...

    async def cleanup(self) -> None:
        """Optional resource cleanup."""
        pass
