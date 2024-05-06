# Local values - to be used during resource creation
locals {
  ami_id = "ami-080e1f13689e07408"
  vpc_id = "vpc-0a6fc55cce6a62372"
  ssh_user = "ubuntu"
  key_name = "Demokey"
  private_key_path = "/home/labsuser/remoteexec/Demokey.pem"
}

# Provider section
provider "aws" {
  access_key = "ASIAXW5N6TJTPRENNMP4"
  secret_key = "n+PDyQacNFbp7EbOKu4h4H9OLpyfZuQtiqBE9F6Q"
  token = "FwoGZXIvYXdzEGQaDNmq56DM3ic4zTmg8yK0AadRbmKXFLcOHqjn5+Lg1LmfRuTkYwutY0OHlYo0nT7+RUTwu53wIIOl8iWJBEpLl5Tzy3HAv5diQWImZ0GhKGdHbKAkvb4cZiFxek5gaPc4kACSsb8WleIekC7LZhCPqzof7GmucJm1UGYgxk3YS3HuGu31mjgHEcRRg9Kz8xzyIZp31VGLAihXX6rMcWItm9Q/hpOIqyQoHukFHmRTvlyvP+r5QCZW7wfqLl4lQHTDhXd8BCjMnt+xBjItHteVShSXo433jbJfzSVSblidYhv/clkAR5cSRxXGlenKKLpoBe9TOr078xVC"
  region = "us-east-1"
}

# AWS security group resource block - 2 inbound & 1 outbound rule added
resource "aws_security_group" "demoaccess" {
  name = "demoaccess"
  vpc_id = local.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# AWS EC2 instance resource block
resource "aws_instance" "web" {
  ami = local.ami_id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.demoaccess.id]
  key_name = local.key_name

  tags = {
    Name = "Demo Test"
  }

  # SSH Connection block which will be used by the provisioners - remote-exec
  connection {
    type = "ssh"
    host = self.public_ip
    user = local.ssh_user
    private_key = file(local.private_key_path)
    timeout = "4m"
  }

  # Remote-exec Provisioner Block - wait for SSH connection
  provisioner "remote-exec" {
    inline = [
      "echo 'wait for SSH connection to be ready...'",
      "touch /home/ubuntu/demo-file-from-terraform.txt"
    ]
  }

  # Local-exec Provisioner Block - create an Ansible Dynamic Inventory
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > myhosts"
  }

  # Local-exec Provisioner Block - execute an ansible playbook
  provisioner "local-exec" {
    command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} playbook_wp.yml"
  }

}

# Output block to print the public ip of instance
output "instance_ip" {
  value = aws_instance.web.public_ip
}



