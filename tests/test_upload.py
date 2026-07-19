"""
Tests for file upload endpoint.
"""
import pytest
import pytest_asyncio


@pytest.mark.asyncio
async def test_upload_requires_auth(client):
    resp = await client.post("/upload", follow_redirects=False)
    assert resp.status_code in (303, 401, 405, 422)


@pytest.mark.asyncio
async def test_upload_with_no_file(auth_client):
    resp = await auth_client.post("/upload")
    assert resp.status_code in (400, 422)
