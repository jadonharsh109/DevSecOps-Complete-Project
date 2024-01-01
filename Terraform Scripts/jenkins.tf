resource "aws_security_group" "jenkins_security_group" {
  name        = "Jenkins_Security_group"
  description = "Jenkins_Security_group is created by Terraform"

  dynamic "ingress" {
    for_each = [80, 22, 8080, 9000]
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

resource "aws_instance" "jenkins_instance" {
  ami             = var.ami
  instance_type   = "t2.large"
  key_name        = aws_key_pair.terraform-key-pair.key_name
  security_groups = ["${aws_security_group.jenkins_security_group.name}"]
  tags = {
    "Name" = "Jenkins-instance"
  }
  root_block_device {
    volume_type = "gp2" # General Purpose SSD (gp2) is a common choice
    volume_size = 20
  }

}

output "ssh" {
  value = "Ssh Key for Jenkins: ssh -i ssh-key ubuntu@${aws_instance.jenkins_instance.public_dns}"
}
