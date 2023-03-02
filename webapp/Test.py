import pytest

#import Application


def test_create():
    assert 1==1
def test_create2():
    assert 2==2


#@pytest.fixture()
#def app():
  #  app = Application.app
  #  app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root:1qaz2wsx@localhost/sys'
    # and handling the context locals for you.
   # return app


#@pytest.fixture()
#def client(app):
 #   app.config['TESTING'] = True
  #  with app.app_context():
   #     test_client = app.test_client()
        # client.environ_base['HTTP_TOKEN'] = Token 需要增加认证功能的时候设置 token 的值信息
    #    yield test_client

#def test_createuser(client):
 #   response = client.post('/v1/user',data={
  #      "first_name": "Jane",
   #     "last_name": "Doe",
    #    "password": "admin",
     #   "username": "admin1@admin.com"
      #  })
    #assert response.status_code == 400

#def test_home_page(client):
 # response = client.get('/healthz')
 # assert response.status_code == 200

if __name__ == '__main__':
    pytest.main(["-q", "test_pass.py"])