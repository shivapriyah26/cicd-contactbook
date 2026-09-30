import os

# Must be set BEFORE importing the app so tests never need a MySQL server.
os.environ["DATABASE_URL"] = "sqlite:///./test.db"
os.environ["APP_VERSION"] = "test"

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402

client = TestClient(app)


def test_health_is_ok():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_create_list_and_delete_contact():
    created = client.post(
        "/contacts", json={"name": "Asha", "email": "asha@example.com", "phone": "123"}
    )
    assert created.status_code == 201
    contact_id = created.json()["id"]

    listed = client.get("/contacts").json()
    assert any(c["id"] == contact_id and c["name"] == "Asha" for c in listed)

    deleted = client.delete(f"/contacts/{contact_id}")
    assert deleted.status_code == 200
    assert all(c["id"] != contact_id for c in client.get("/contacts").json())


def test_delete_missing_contact_returns_404():
    assert client.delete("/contacts/999999").status_code == 404
