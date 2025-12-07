import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.models.user import User
from app.crud.user import create_user
from app.core.security import create_access_token

@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c

@pytest.fixture
def test_user():
    user_data = {
        "username": "testuser",
        "email": "testuser@example.com",
        "password": "testpassword"
    }
    user = create_user(user_data)
    return user

def test_login(client, test_user):
    response = client.post("/api/v1/auth/login", data={
        "username": test_user.username,
        "password": "testpassword"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_login_invalid_user(client):
    response = client.post("/api/v1/auth/login", data={
        "username": "invaliduser",
        "password": "wrongpassword"
    })
    assert response.status_code == 401
    assert response.json() == {"detail": "Invalid credentials"}

def test_access_token(client, test_user):
    token = create_access_token(data={"sub": test_user.username})
    response = client.get("/api/v1/users/me", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    assert response.json()["username"] == test_user.username