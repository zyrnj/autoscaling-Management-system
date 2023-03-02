
resource "aws_vpc" "zyrnj" {
  cidr_block = var.cidr
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  vpc_id = "${aws_vpc.zyrnj.id}"
  availability_zone = var.availability_zone_names[count.index]
  map_public_ip_on_launch = true
  cidr_block = element(var.public_subnet_cidrs, count.index)

  tags = {
   Name = "Public Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  vpc_id = "${aws_vpc.zyrnj.id}"
  availability_zone = var.availability_zone_names[count.index+length(var.public_subnet_cidrs)]
  map_public_ip_on_launch = false
  cidr_block = element(var.private_subnet_cidrs, count.index)

  tags = {
   Name = "Private Subnet ${count.index + 1}"
  }
}
resource "aws_internet_gateway" "example" {
  vpc_id = "${aws_vpc.zyrnj.id}"

}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.zyrnj.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.example.id}"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.zyrnj.id}"
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_security_group" "db_sg" {
  name_prefix = "database_sg"
  description = "database security group"
  vpc_id      = aws_vpc.zyrnj.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
security_groups = [aws_security_group.app_sg.id]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
security_groups = [aws_security_group.app_sg.id]
  }
}

resource "aws_security_group" "app_sg" {
  name_prefix = "app_sg"
  vpc_id      = aws_vpc.zyrnj.id

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## s3part 

resource "random_id" "my-random-id" {
byte_length = 8
}

resource "aws_s3_bucket" "zyrnj" {
  bucket = "zyrnj-bucket-${random_id.my-random-id.dec}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "example_bucket_acl" {
  bucket = aws_s3_bucket.zyrnj.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.zyrnj.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "zyrnj" {
  bucket = aws_s3_bucket.zyrnj.id

  rule {
    id = "rule-1"

    transition {
        days          = 30
        storage_class = "STANDARD_IA"
     }

    status = "Enabled"
  }
}


##database part
resource "aws_db_parameter_group" "zyrnj" {
  name        = "zyrnj-db-parameter-group"
  family      = "mysql8.0"
  description = "Example MySQL 8.0 Parameter Group"

  parameter {
    name  = "max_connections"
    value = "500"
  }
}


resource "aws_db_subnet_group" "zyrnj" {
  name       = "main"
  subnet_ids = [aws_subnet.private[0].id,aws_subnet.private[1].id,aws_subnet.private[2].id]

  tags = {
    Name = "My DB subnet group"
  }
}
resource "aws_db_instance" "zyrnj" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  multi_az             = false
  identifier           = "csye6225"
  db_name              = "csye6225"
  username             = "csye6225"
  password             = "1qaz2wsx"
  db_subnet_group_name = aws_db_subnet_group.zyrnj.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  parameter_group_name = aws_db_parameter_group.zyrnj.name
  publicly_accessible  = false
  skip_final_snapshot  = true
  tags = {
    Name = "zyrnj RDS Instance"
  }
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "S3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.zyrnj.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.zyrnj.bucket}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  name   = "s3-access-policy"
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example_attachment" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "example-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "web" {
  ami           = var.dev-ami
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y mysql
    echo "export DB_USERNAME=csye6225" >> /etc/environment
    echo "export DB_PASSWORD=1qaz2wsx" >> /etc/environment
    echo "export DB_HOSTNAME=${aws_db_instance.zyrnj.endpoint}" >> /etc/environment
    echo "export S3_BUCKET_NAME=${aws_s3_bucket.zyrnj.bucket}" >> /etc/environment
    echo "DB_USERNAME=csye6225" >> /tmp/myapp.conf
    echo "DB_PASSWORD=1qaz2wsx" >> /tmp/myapp.conf
    echo "DB_HOSTNAME=${aws_db_instance.zyrnj.endpoint}" >> /tmp/myapp.conf
    echo "S3_BUCKET_NAME=${aws_s3_bucket.zyrnj.bucket}" >> /tmp/myapp.conf
    source /etc/environment
    sudo systemctl daemon-reload 
    sudo systemctl enable myscript.service 
    sudo systemctl restart myscript.service 
    EOF
  
  root_block_device {
    volume_size = 50 # Set root volume size to 50 GB
    volume_type = "gp2" # Use General Purpose SSD (GP2) as root volume type
    delete_on_termination = true # Delete root volume on instance termination
  }

  tags = {
    Name = "Assignment5-ec2"
  }
}