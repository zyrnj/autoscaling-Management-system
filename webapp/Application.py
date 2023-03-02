import datetime
import json
import re
import boto3
import os
from flask import request, app, Flask
from flask_sqlalchemy import SQLAlchemy
from flask_httpauth import HTTPBasicAuth
from flask_bcrypt import Bcrypt

app = Flask(__name__)
db_username = os.environ.get('DB_USERNAME')
db_password = os.environ.get('DB_PASSWORD')
db_hostname = os.environ.get('DB_HOSTNAME')
s3_bucket_name = os.environ.get('S3_BUCKET_NAME')

app.config['SQLALCHEMY_DATABASE_URI'] = f'mysql+pymysql://{db_username}:{db_password}@{db_hostname}/sys'
#app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://root:1qaz2wsx@localhost/sys'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
auth = HTTPBasicAuth()

AWS_ACCESS_KEY_ID = 'AKIAZIRVDJPHI53ZWN4I'
AWS_SECRET_ACCESS_KEY = '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'
AWS_REGION = 'us-east-1'
AWS_BUCKET_NAME = s3_bucket_name

# S3 client
s3 = boto3.client('s3',
                  aws_access_key_id=AWS_ACCESS_KEY_ID,
                  aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
                  region_name=AWS_REGION)
@auth.verify_password
def verify_password(username, password):
    query=db.session.query(User).filter_by(username=username).all()
    if query and bcrypt.check_password_hash(query[0].password,password):
    #if username in users and password == users[username]:
        return username,query[0].id

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    first_name = db.Column(db.String(80))
    last_name = db.Column(db.String(80))
    password = db.Column(db.String(80))
    username = db.Column(db.String(80), unique=True)
    account_created=db.Column(db.DateTime,default=datetime.datetime.now())
    account_updated=db.Column(db.DateTime,default=datetime.datetime.now(),onupdate=datetime.datetime.now())

    def __init__(self, first_name, last_name, password, username):
        self.username = username
        self.first_name=first_name
        self.last_name=last_name
        self.password=bcrypt.generate_password_hash(password, 10)

    def to_json(self):
        return {
            'id': self.id,
            'username': self.username,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'account_created': self.account_created.strftime("%Y-%m-%d %H:%M:%S"),
            'account_updated': self.account_updated.strftime("%Y-%m-%d %H:%M:%S")
        }

class Product(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80))
    description = db.Column(db.String(80))
    sku = db.Column(db.String(80), unique=True)
    manufacturer = db.Column(db.String(80))
    quantity = db.Column(db.Integer)
    date_added = db.Column(db.DateTime, default=datetime.datetime.now())
    date_last_updated = db.Column(db.DateTime, default=datetime.datetime.now(), onupdate=datetime.datetime.now())
    owner_user_id = db.Column(db.Integer)

    def __init__(self, name, description, sku, manufacturer, quantity,id):
        self.name = name
        self.description=description
        self.sku=sku
        self.manufacturer=manufacturer
        self.quantity=quantity
        self.owner_user_id=id

    def to_json(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'sku': self.sku,
            'manufacturer': self.manufacturer,
            'quantity': self.quantity,
            'date_added': self.date_added.strftime("%Y-%m-%d %H:%M:%S"),
            'date_last_updated': self.date_last_updated.strftime("%Y-%m-%d %H:%M:%S"),
            'owner_user_id': self.owner_user_id
        }

class Image(db.Model):
    image_id=db.Column(db.Integer, primary_key=True)
    product_id = db.Column(db.Integer)
    file_name = db.Column(db.String(80))
    date_created = db.Column(db.DateTime, default=datetime.datetime.now())
    s3_bucket_path = db.Column(db.String(300))
    owner_user_id = db.Column(db.Integer)
    key = db.Column(db.String(80))

    def __init__(self, product_id, file_name, s3_bucket_path,owner_user_id,key):
        self.product_id = product_id
        self.file_name=file_name
        self.s3_bucket_path=s3_bucket_path
        self.owner_user_id=owner_user_id
        self.key=key
    def to_json(self):
        return {
            "image_id": self.image_id,
            "product_id": self.product_id,
            "file_name": self.file_name,
            'date_created': self.date_created.strftime("%Y-%m-%d %H:%M:%S"),
            "s3_bucket_path": self.s3_bucket_path
        }

with app.app_context():
    db.create_all()

@app.route('/v1/user', methods=['GET', 'PUT'])
@auth.login_required
def index():
    userID=request.args.get('id')
    query = db.session.query(User).filter_by(id=userID).all()
    if not query:
        return 'forbidden', 403
    result = query[0].to_json()
    print(auth.current_user())
    if request.method == 'GET':
        if result and auth.username()==result.get('username'):
            response = json.dumps(result)
            return response, 201
        else:
            return 'forbidden', 403
    elif request.method == 'PUT':
        data = request.get_json()
        if data.get('id') or data.get('username') or data.get('account_created') or data.get('account_updated'):
            return 'Bad Request', 400
        if not result or auth.username()!=result.get('username'):
            return 'forbidden', 403
        if data.get('password'):
            query[0].password =bcrypt.generate_password_hash(data.get('password'))
        if data.get('first_name'):
            query[0].first_name = data.get('first_name')
        if data.get('last_name'):
            query[0].last_name = data.get('last_name')
        db.session.commit()
        return 'no content', 204

@app.route('/v1/user', methods=['POST'])  # 代表个人中心页
def createUser():  # 视图函数
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    hashPassword = bcrypt.generate_password_hash(password, 10)
    firstName = data.get('first_name')
    lastName = data.get('last_name')
    q=User.query.filter_by(username=username).first()
    if q or not re.match("^.+\\@(\\[?)[a-zA-Z0-9\\-\\.]+\\.([a-zA-Z]{2,3}|[0-9]{1,3})(\\]?)$", username):
        return 'Bad Request', 400
    else:
        me = User(firstName,lastName, password, username)
        db.session.add(me)
        query=db.session.query(User).filter_by(username=me.username).all()
        response=json.dumps(query[0].to_json())
        db.session.commit()
        return response

@app.route('/healthz', methods=['GET'])  # 代表个人中心页
def get():  # 视图函数
    return 'healthy', 200

@app.route('/v1/product', methods=['GET'])
def getProduct():  # 视图函数
    query=db.session.query(Product).filter_by(id=request.args.get('productID')).all()
    if query:
        response = json.dumps(query[0].to_json())
        return response, 200
    else:
        return 'Forbidden',403

@app.route('/v1/product', methods=['POST'])
@auth.login_required()
def createProduct():
    data = request.get_json()
    query = db.session.query(User).filter_by(username=auth.username()).all()
    quantity=data.get('quantity')
    if data.get('name') and data.get('description') and data.get('sku') and data.get('manufacturer') \
          and quantity and isinstance(quantity,int) and quantity<=100 and quantity>=1:
        newproduct = Product(data.get('name'),data.get('description'),data.get('sku'),data.get('manufacturer'),data.get('quantity'),query[0].id)
        db.session.add(newproduct)
        db.session.commit()
        return newproduct.to_json(),201
    else:
        return 'Bad Request',400

@app.route('/v1/product', methods=['PUT'])
@auth.login_required()
def updateProduct():
    data = request.get_json()
    product=db.session.query(Product).filter_by(id=request.args.get('productID')).first()
    print(product)
    quantity = data.get('quantity')
    if not product or auth.current_user()[1]!=product.owner_user_id:
        return 'Forbidden',403
    elif data.get('name') and data.get('description') and data.get('sku') and data.get('manufacturer') \
          and quantity and isinstance(quantity,int) and quantity<=100 and quantity>=1:
        product.name=data.get('name')
        product.description=data.get('description')
        product.sku=data.get('sku')
        product.manufacturer=data.get('manufacturer')
        product.quantity=quantity
        db.session.commit()
        return 'No content', 204
    else:
        return 'Bad Request',400

@app.route('/v1/product', methods=['PATCH'])
@auth.login_required()
def updateProduct2():
    data = request.get_json()
    product=db.session.query(Product).filter_by(id=request.args.get('productID')).first()
    print(product)
    if not product or auth.current_user()[1]!=product.owner_user_id:
        return 'Forbidden',403
    if data.get('quantity'):
        quantity = data.get('quantity')
        if isinstance(quantity,int) and quantity<=100 and quantity>=1:
            product.quantity=quantity
        else:
            return 'Bad Request',400
    if data.get('name'):
        product.name=data.get('name')
    if data.get('description'):
        product.description=data.get('description')
    if data.get('sku'):
        product.sku=data.get('sku')
    if data.get('manufacturer'):
        product.manufacturer=data.get('manufacturer')
    db.session.commit()
    return 'No content', 204

@app.route('/v1/product', methods=['DELETE'])
@auth.login_required()
def deleteProduct():
    product = db.session.query(Product).filter_by(id=request.args.get('productID')).first()
    if not product:
        return 'Not Found',404
    elif auth.current_user()[1]!=product.owner_user_id:
        return 'Forbidden', 403
    else:
        db.session.delete(product)
        db.session.commit()
        return 'No content', 204

ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'gif'}

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
@app.route('/v1/product/image', methods=['POST'])
@auth.login_required()
def uploadimage():
    productId=request.args.get('productID')
    files = request.files.getlist('file')
    for file in files:
        if not file or not allowed_file(file.filename):
            return 'Bad Request',400
        query=db.session.query(Product).filter_by(id=productId).first()
        if not query or query.owner_user_id!=auth.current_user()[1]:
            return "you can't upload to product you don't own",403
    #metadata = {'key1': 'value1', 'key2': 'value2'}  # Replace with your own metadata
        file_name = file.filename
        num = db.session.query(Image).filter_by(file_name=file_name).count()
        key = file_name+str(num)
        url = f"https://{AWS_BUCKET_NAME}.s3.{AWS_REGION}.amazonaws.com/{key}"
        newImage = Image(productId, file_name, url,auth.current_user()[1],key)
        db.session.add(newImage)
        db.session.commit()
        s3.upload_fileobj(file, AWS_BUCKET_NAME, key)
    return newImage.to_json(),201

@app.route('/v1/product/image', methods=['GET'])
@auth.login_required()
def getimage():
    if not request.args.get('imageID'):
        query=db.session.query(Image).filter_by(product_id=request.args.get('productID')).all()
        list1=[]
        for oneimage in query:
            if oneimage.owner_user_id!=auth.current_user()[1]:
                return 'Forbidden',403
            list1.append(oneimage.to_json())
        return list1
    else:
        query = db.session.query(Image).filter_by(image_id=request.args.get('imageID')).all()
        if query[0].owner_user_id!=auth.current_user()[1]:
            return 'Forbidden', 403
        return query[0].to_json()

@app.route('/v1/product/image', methods=['DELETE'])
@auth.login_required()
def deleteimage():
    query = db.session.query(Image).filter_by(image_id=request.args.get('imageID')).first()
    if not query:
        return 'Not found',404
    if query.owner_user_id!=auth.current_user()[1]:
        return 'Forbidden', 403
    else:
        s3.delete_object(Bucket=AWS_BUCKET_NAME, Key=query.key)
        db.session.delete(query)
        db.session.commit()
        return 'No content', 204

if __name__ == '__main__':
    app.run( host='0.0.0.0', port=8080)# 运行程序

