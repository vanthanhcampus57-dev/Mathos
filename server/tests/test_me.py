import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_get_and_update_profile(client: AsyncClient):
    # 1. Register
    reg_payload = {
        "email": "profile_user@mathos.local",
        "password": "SecretPassword123",
        "display_name": "Original Name"
    }
    reg_res = await client.post("/api/v1/auth/register", json=reg_payload)
    token = reg_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Get Profile
    get_res = await client.get("/api/v1/me/profile", headers=headers)
    assert get_res.status_code == 200
    data = get_res.json()
    assert data["display_name"] == "Original Name"
    assert data["email"] == "profile_user@mathos.local"
    assert data["onboarding_completed"] == False

    # 3. Update Profile
    update_payload = {
        "display_name": "Updated Hero Name",
        "onboarding_completed": True,
        "avatar_ref": "avatar_hero_01.png"
    }
    patch_res = await client.patch("/api/v1/me/profile", json=update_payload, headers=headers)
    assert patch_res.status_code == 200
    updated_data = patch_res.json()
    assert updated_data["display_name"] == "Updated Hero Name"
    assert updated_data["onboarding_completed"] == True
    assert updated_data["avatar_ref"] == "avatar_hero_01.png"

@pytest.mark.asyncio
async def test_profile_unauthorized_access(client: AsyncClient):
    # No auth header
    res1 = await client.get("/api/v1/me/profile")
    assert res1.status_code == 422 # missing header

    # Invalid token
    res2 = await client.get("/api/v1/me/profile", headers={"Authorization": "Bearer invalid_token_123"})
    assert res2.status_code == 401
