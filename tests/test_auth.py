"""
Tests for authentication routes.
"""
import pytest
import pytest_asyncio


@pytest.mark.asyncio
async def test_login_page(client):
    resp = await client.get("/auth/login")
    assert resp.status_code == 200
    assert "Войти" in resp.text or "Login" in resp.text


@pytest.mark.asyncio
async def test_register_page(client):
    resp = await client.get("/auth/register")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_login_with_invalid_credentials(client):
    resp = await client.post(
        "/auth/login",
        data={"username": "nonexistent", "password": "wrong"},
        follow_redirects=False,
    )
    # Should redirect back to login (303) or show error
    assert resp.status_code in (200, 303, 401, 422)


@pytest.mark.asyncio
async def test_profile_requires_auth(client):
    resp = await client.get("/profile/", follow_redirects=False)
    assert resp.status_code == 303


@pytest.mark.asyncio
async def test_profile_page(auth_client):
    resp = await auth_client.get("/profile/")
    assert resp.status_code == 200
    assert "Профиль" in resp.text or "Profile" in resp.text
