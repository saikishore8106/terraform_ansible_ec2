
provider "aws" {
  region = "eu-north-1"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "auto-gen-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/id_rsa"
  file_permission = "0600"
}

resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  description = "Allow SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "instance_count" {
  default = 3
}

resource "aws_instance" "ec2_instances" {
  count         = var.instance_count
  ami           = "ami-042b4708b1d05f512" # Amazon Linux 2
  instance_type = "t3.micro"
  key_name      = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "TerraformAnsible${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y python3"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = self.public_ip
    }
  }
}

output "public_ips" {
  value = aws_instance.ec2_instances[*].public_ip
}

output "private_key_path" {
  value = local_file.private_key.filename
}
