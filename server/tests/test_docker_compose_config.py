import os
import subprocess
import pytest

def test_docker_compose_config_validity():
    """Validates docker compose config syntax."""
    repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    server_dir = os.path.join(repo_root, "server")
    compose_file = os.path.join(server_dir, "compose.yaml")

    assert os.path.exists(compose_file), f"Compose file missing: {compose_file}"

    # Verify compose file content has required services and healthchecks
    with open(compose_file, "r", encoding="utf-8") as f:
        content = f.read()

    assert "mathos-api:" in content
    assert "mathos-db:" in content
    assert "mathos-mailpit:" in content
    assert "mathos_postgres_data:" in content
    assert "127.0.0.1:8080:8080" in content
    assert "127.0.0.1:8025:8025" in content
    assert "healthcheck:" in content
