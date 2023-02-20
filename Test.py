import pytest
import Application
from Application import db

@pytest.fixture()
def app():
    app = Application.app
    # and handling the context locals for you.
    app.config.update({
        "TESTING": True,
    })
    yield app

@pytest.fixture()
def client(app):
    return app.test_client()

def test_createuser(client):
    with client:
        response = client.post('/v1/user',data={
        "first_name": "Jane",
        "last_name": "Doe",
        "password": "admin",
        "username": "admin1@admin.com"
        })
        assert response.status_code == 400

def test_createuser_notemail(client):
    response = client.post('/v1/user',data={
    "first_name": "Jane",
    "last_name": "Doe",
    "password": "somepassword",
    "username": "jane.doeexample.com"
})
    assert response.status_code == 400



def test_home_page(client):
  response = client.get('/healthz')
  assert response.status_code == 200

if __name__ == '__main__':
    pytest.main(["-q", "test_pass.py"])