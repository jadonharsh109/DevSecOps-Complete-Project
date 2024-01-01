resource "aws_key_pair" "terraform-key-pair" {
  key_name   = "ssh-key"
  public_key = file("${path.module}/ssh-key.pub")
}
