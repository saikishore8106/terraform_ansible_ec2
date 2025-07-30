provider "aws" {
  region = "us-east-1"  # Change if needed
}

# Generate SSH key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the public key to AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Security Group to allow SSH
resource "aws_security_group" "ssh" {
  name_prefix = "terraform-ssh-"

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
  default = 2
}

resource "aws_instance" "ec2_instances" {
  count         = var.instance_count
  ami           = "ami-0fc5d935ebf8bc3bc" # ✅ Ubuntu 22.04 LTS in us-east-1
  instance_type = "t3.micro"
  key_name      = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "TerraformAnsible-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python3 python3-pip"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = self.public_ip
    }
  }
}

# Output instance IPs and save SSH private key
output "instance_ips" {
  value = aws_instance.ec2_instances[*].public_ip
}

output "private_key_pem" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
