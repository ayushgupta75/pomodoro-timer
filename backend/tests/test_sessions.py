from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from app.models.user import User


def make_mock_user() -> User:
    return User(id="apple_test_123", email="test@example.com")


@pytest.mark.asyncio
async def test_sync_sessions_unauthorized() -> None:
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/sessions/sync", json={"sessions": []})
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_sync_sessions_invalid_token() -> None:
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/sessions/sync",
            json={"sessions": []},
            headers={"Authorization": "Bearer invalid_token"},
        )
    assert response.status_code == 401
