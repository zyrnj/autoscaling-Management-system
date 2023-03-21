variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami" {
  type    = string
  default = "ami-006dcf34c09e50022" # Amazon Linux 2 AMI (HVM)
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

variable "subnet_id" {
  type    = string
  default = "subnet-011a382d8acb737b4"
}


# https://www.packer.io/plugins/builders/amazon/ebs
source "amazon-ebs" "my-ami" {
  region     = "${var.aws_region}"
  ami_name        = "csye6225_${formatdate("YYYY_MM_DD_hh_mm_ss", timestamp())}"
  ami_description = "AMI for CSYE 6225"
  ami_regions = [
    "us-east-1"
  ]

  aws_polling {
    delay_seconds = 120
    max_attempts  = 50
  }


  instance_type = "t2.micro"
  source_ami    = "${var.source_ami}"
  ssh_username  = "${var.ssh_username}"
  subnet_id     = "${var.subnet_id}"
  vpc_id = "vpc-0139809c4462101f0"
  ami_users = ["636840266702"]

  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sdf"
    volume_size           = 8
    volume_type           = "gp2"
  }
}

build {
  sources = ["source.amazon-ebs.my-ami"]
  
  provisioner "file" {
    source = "webapp"
    destination = "/tmp/webapp"
  }
  provisioner "file" {
    source = "cloudwatch-config.json"
    destination = "/tmp/cloudwatch-config.json"
  }
  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "CHECKPOINT_DISABLE=1"
    ]
    inline = [
      "sudo yum upgrade -y",
      "sudo yum update -y",
      "sudo amazon-linux-extras install nginx1",
	"sudo yum install amazon-cloudwatch-agent",
	"sudo amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/tmp/cloudwatch-config.json",
	"sudo python3 -m pip install flask cryptography Flask-SQLAlchemy PyMySQL Flask-Bcrypt Flask-HTTPAuth boto3",
	"echo  >> /tmp/myapp.conf",
	"sudo cp /tmp/webapp/myscript.service /etc/systemd/system/",
	"sudo systemctl daemon-reload ",
	"sudo systemctl enable myscript.service ",
	"sudo systemctl start myscript.service ",
      "sudo yum clean all",
    ]
  }
}
