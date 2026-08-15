from fastapi.testclient import TestClient

from app.main import create_app


def test_health_reports_scaffold_state() -> None:
    response = TestClient(create_app()).get("/api/v1/health")

    assert response.status_code == 200
    assert response.json() == {
        "app": "ok",
        "database": "not_configured",
        "comfyui": "not_checked",
        "sdcpp": "not_checked",
        "ollama": "not_checked",
    }
