provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}


resource "aws_key_pair" "splunk-key-pair" {
  key_name   = "splunk-ssh-key"
  public_key = file("${path.module}/ssh-key.pub")
}

resource "aws_security_group" "splunk_security_group" {
  name        = "splunk_Security_group"
  description = "splunk_Security_group is created by Terraform"

  dynamic "ingress" {
    for_each = [22, 8000]
    iterator = port

    content {
      description      = "Rule by Terraform"
      from_port        = port.value
      to_port          = port.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_instance" "splunk_instance" {
  ami             = "ami-03f4878755434977f"
  instance_type   = "t2.medium"
  key_name        = aws_key_pair.splunk-key-pair.key_name
  security_groups = ["${aws_security_group.splunk_security_group.name}"]
  tags = {
    "Name" = "splunk-instance"
  }
  root_block_device {
    volume_type = "gp2" # General Purpose SSD (gp2) is a common choice
    volume_size = 24
  }

}

# output "splunkurl" {
#   value = "http://${aws_instance.splunk_instance.public_ip}:8080"
# }

output "ssh" {
  value = "ssh -i ssh-key ubuntu@${aws_instance.splunk_instance.public_dns}"
}
