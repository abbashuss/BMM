from typing import Literal

from fastapi import FastAPI
from pydantic import BaseModel


class HealthResponse(BaseModel):
    app: Literal["ok"]
    database: Literal["not_configured"]
    comfyui: Literal["not_checked"]
    sdcpp: Literal["not_checked"]
    ollama: Literal["not_checked"]


def create_app() -> FastAPI:
    application = FastAPI(
        title="Private AI Studio API",
        version="0.1.0",
        docs_url="/api/docs",
        openapi_url="/api/openapi.json",
    )

    @application.get("/api/v1/health", response_model=HealthResponse, tags=["system"])
    def health() -> HealthResponse:
        return HealthResponse(
            app="ok",
            database="not_configured",
            comfyui="not_checked",
            sdcpp="not_checked",
            ollama="not_checked",
        )

    return application


app = create_app()
