# Deploy multiple EC2 instances via Terraform

## Steps

- Download and install Terraform

- Initialize a project repository

- Create infrastructure

- Unleash Terraform


## Download and install Terraform

Download the appropriate package from 

[Terraform&#39;s website]: https://learn.hashicorp.com/terraform/getting-started/install.html

 unzip it then create a symbolic link to the terraform binary!

```bash
cd /usr/bin
sudo ln -s <path to the terraform binary> terraform
```

## Initialize a project repository

Navigate into the project repository and initialize it for Terraform!

Note: When applied Terraform will read every file with .tf extension in the repository so make sure that your project repo only contains .tf files that you really need.

```bash
terraform init
```

## Create infrastructure

The set of files that describe a Terraform infrastructure is called configuration. Configuration files have .tf extension and are written in Terraform's own language. Terraform can manage multiple providers even within a single configuration. For this example I will use only AWS.

In the configuration files declare the provider and provide your security credentials and the region where you want to launch your servers.

```
# main.tf

provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}
```

To provide your credentials you can use the acces_key and the secret_key arguments or you can point to an already existing aws profile at ~/.aws/credentials (in this case the credentials file contains the access ID and the secret access key).

You can hardcode your settings but it is better to declare variables for them in a separate file and reference them like below.

```
# var.tf

variable "aws_credentials" {
  type = "list"
  default = ["aws access id", "aws secret access key"]
}
```

```
# main.tf

provider "aws" {
  access_key = var.aws_credentials[0]
  secret_key = var.aws_credentials[1]
}
```

To create the infrastructure you have to describe the instances you want to launch. First tell Terraform which resources of the provider you want to use then describe the settings of that resource!

```
# main.tf

resource "aws_instance" "example" {
  count           = 3 
  ami             = "ami-00f94dc949fea2adf"
  instance_type   = "t2.micro"
}
```

With the count argument you can set how many instances you want to launch, the ami argument sets the OS of all the instances and the instance_type argument tells the size of the servers.

Note: count is a global argument it can be used for every resource and you can refer to the order of a single instance with ${count.index}.

Note: AWS uses different IDs for the same OS in different regions. You can consult [this website] (https://cloud-images.ubuntu.com/locator/ec2/) for the appropriate ami ID.

Terraform is also able to reach and manipulate the servers you launched via SSH. To enable this function you must open  a port for this type of connection then create a key-pair, register the public-key with AWS, add this key-pair to the EC2 instance's settings then describe the details of the connection.

To open a port for SSH you must use the aws_security_group resource like in the example below.

```
# sec_gr.tf

resource "aws_security_group" "example_sec_group" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

The ingress block describes a security rule which enables TCP connection on port 22 from any IP address. You can declare multiple ingress and egress blocks for a single security group.

To add this security group to the EC2 instances add the following line to the aws_instance resource block!

```
# main.tf

resource "aws_instance" "example" {
  ...
  security_groups = ["${aws_security_group.example_sec_group.name}"]
}
```

At the moment the AWS provider doesn't have a resource to create a key pair but the aws_key_pair resource can manage the registration process of an already existing one. You can create the key-pair with ssh-keygen then import it with the mentioned resource.

```
# ssh_key.tf

resource "aws_key_pair" "example_key" {
  key_name = "example_ssh_key"
  public_key = "the public key of the generated key-pair"
}
```

Note: Consult [this website] (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws) for the appropriate key format!

To associate this key-pair with the EC2 instances add the following line to the aws_instance declaration block!

```
# main.tf

resource "aws_instance" "example" {
  ...
  key_name = "${aws_key_pair.example_key.key_name}"
}
```

Within the aws_instance block provide the details of the connection like in the example below!

```
# main.tf

resource "aws_instance" "example" {
  ...
  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    private_key = "the private key of the generated key-pair"
    }
}
```

Note: Instead of copying the generated keys you can reference them like file("path to the .pem file")

Note: If you have a key-pair that is already registered with AWS you don't need the aws_key_pair resource and you can use the registered name of that key-pair for the key_name argument and the the downloaded .pem file for  the private_key argument.

To manipulate the launched servers you can use provisioners. The file provisioner can copy the specified files to the remote server and the remote-exec provisioner can execute the provided commands on the remote server. The example below copies a script file then executes it on the remote server.

```
# main.tf

resource "aws_instance" "example" {
  ...
  security_groups = ["${aws_security_group.example_sec_group.name}"]
  key_name        = "${aws_key_pair.example_key.key_name}"
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    private_key = "the private key of the generated key-pair"
    }
    
  provisioner "file" {
    source      = ./scripts/example.sh
    destination = /tmp/example.sh
  }
  
  provisioner "remote-exec" {
    inline = [
      "bash /tmp/example.sh"
    ]
  }
}
```

## Unleash Terraform

To launch the environment you created in the configuration execute the following command in the repository where your configuration files are located!

```
terraform apply
```

To terminate every instance created by this configuration execute 

```
terraform destroy
```

## Notes and best practices

To learn more about the providers and resources see [Terraform's documentations] (https://www.terraform.io/docs/providers/index.html) !

Make sure to store all sensitive data (like AWS credentials, SSH keys) in a separate file and add this file to .gitignore! You may transfer these informations by secure copying the files to the remote servers if necessary.

To make your configuration reusable separate the different resources into different files and create variables for settings that may change!