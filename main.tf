provider "aws" {
  profile    = "default"
  region     = "eu-west-2"
}

resource "aws_security_group" "hello_with_terraform" {
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "hello_with_terraform" {
  count           = 3 
  ami             = "ami-00f94dc949fea2adf"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.hello_with_terraform.name}"]
  key_name        = "malac2-helloworld"

  tags            = {
    Name = "fedex-${element(var.tag_names, count.index)}"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    private_key = file("/home/nora/greenfox/projectPhase/malac2-helloworld.pem")
  }

  provisioner "file" {
    source      = "./scripts/"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /tmp/setup.sh",
      "bash /tmp/get_dependencies.sh",
      "bash /tmp/deploy.sh"
    ]
  }
}
