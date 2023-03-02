# webapp

Build instruction:
//1. set up mysql server on your laptop

//2. mysql configuration: host='0.0.0.0', user='root', password='1qaz2wsx', database='sys', table=user

//3. python version should be 3.9 

//4. Before run, install these package for python: Flask, pytest, Flask-HTTPAuth, Flask-bcrypt, Flask-SQLAlchemy, PyMySQL, boto3 

//5. test using pytest, to run test please don't remove, rename Test.py file

Set up application on AWS:
1.run packer build ami.pkr.hcl to build AMI in AWS

2.when merge request the packer would be autoly run

3.cd terraform and run 'terraform init && terraform apply 'to build infrastructure

4.the application will configure itself in the aws instance
