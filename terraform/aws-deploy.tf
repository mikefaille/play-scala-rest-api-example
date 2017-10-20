// https://terraformtraining.com/2017/07/24/how-to-create-a-vpc-with-terraform/
// https://nbari.com/post/terraform-full-vp/
// http://bryankendall.com/2016/04/09/01-terraform.html
// https://dzone.com/articles/using-nat-gateway-instead-of-nat-instance-with-aws
resource "aws_vpc" "my_vpc" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_classiclink = false
  tags {
    Name = "tf-example"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.my_vpc.id}"
}

resource "aws_default_route_table" "terraformtraining-public" {
  # vpc_id = "${aws_vpc.my_vpc.id}"
  default_route_table_id = "${aws_vpc.my_vpc.default_route_table_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "terraformtraining-public"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id                  = "${aws_vpc.my_vpc.id}"
  cidr_block              = "172.31.10.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ca-central-1a"
  depends_on = ["aws_internet_gateway.gw"]
  tags {
    Name = "tf-example"
  }
}

# resource "aws_route_table_association" "terraformtraining-public" {
#   subnet_id = "${aws_subnet.my_subnet.id}"
#   route_table_id = "${aws_default_route_table.terraformtraining-public.id}"
#   # depends_on = ["aws_default_route_table.terraformtraining-public"]
# }

resource "aws_security_group" "allow_cedille" {
  name        = "allow_cedille"
  description = "Allow basics access like ssh inbound traffic"

  vpc_id = "${aws_vpc.my_vpc.id}"
  depends_on = ["aws_internet_gateway.gw"]
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow_cedille"
  }
}

# resource "aws_eip" "bar" {
#   vpc = true

#   instance                  = "${aws_instance.example.id}"
#   # associate_with_private_ip = "aws_network_interface.private_ips"
# }

# resource "aws_nat_gateway" "terraformtraining-nat-gw" {
#   allocation_id = "${aws_eip.bar.id}"
#   subnet_id = "${aws_subnet.terraformtraining-public.id}"
#   depends_on = ["aws_internet_gateway.gw"]
# }

resource "aws_network_interface" "foo" {
  subnet_id   = "${aws_subnet.my_subnet.id}"
  private_ips = ["172.31.10.100"]

  tags {
    Name = "primary_network_interface"
  }

  # vpc_security_group_ids = [ "${aws_security_group.allow_cedille.id}" ]
  security_groups = ["${aws_security_group.allow_cedille.id}"]
}

provider "aws" {
  # -- dummy keys --
  # access_key = "AKIAIT4FBNFGSQMCIQYA"
  # secret_key = "7fg4DQAoyh1eALrS1uMzS90SReMyVomMByX3dVX9"
  region     = "ca-central-1"
}

resource "aws_instance" "example" {
  ami           = "ami-3709b053"
  instance_type = "t2.nano"
  key_name      = "admin_key"
  # vpc_id = "${aws_vpc.my_vpc.id}"
  # security_groups = [ "${aws_security_group.allow_cedille.id}" ]
  # vpc_security_group_ids = [ "${aws_security_group.allow_cedille.id}" ]
  network_interface {
    network_interface_id = "${aws_network_interface.foo.id}"
    device_index         = 0
  }

  connection {
    type     = "ssh"
    user     = "admin"
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y ansible git",
      "sudo ansible-galaxy install geerlingguy.docker geerlingguy.pip",
      "sudo git init ansible-playbook",
      "cd ~/ansible-playbook && sudo git remote add origin https://github.com/mikefaille/play-scala-rest-api-example",
      "cd ~/ansible-playbook && sudo git config core.sparsecheckout true",
      "cd ~/ansible-playbook && echo 'ansible/*' | sudo tee .git/info/sparse-checkout",
      "cd ~/ansible-playbook && sudo git pull --depth=1 origin master",
      "cd ~/ansible-playbook/ansible && sudo ansible-playbook -e PUBLIC_DNS=${aws_instance.example.public_dns}  -i 'localhost,' -c local  site.yml -v",
    ]
  }

  # provisioner "file" {
  #   source      = "get-docker.sh"
  #   destination = "/tmp/get-docker.sh"
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "chmod +x /tmp/get-docker.sh",
  #     "/tmp/get-docker.sh",
  #   ]
  # }
}

resource "aws_key_pair" "admin_key" {
  key_name   = "admin_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD0JK1UOINwYMThTaduUs8ePMPI2pKRvjQhxXlZebgvjdmOejQjS46cOII0CPqqJv93zBwlGLhn+6Au+T7wP4Ugzi1/JXBmJATLYHqkV2sjP7No2eO3IHGk13lgFcBLm0fchhqvlMGQnSMaXnU5Uoi7JuCjVQRetWYTf/H+bPJsgTxOcIqSdmd71MS0KmbAeiQeDvxJUZZYfBhY7usSCdHVmwsehQFiem1DmrtBnO/vciRyVa9tAVPIUHYHVpt+8drAwh4sCucdC4f2vuVbyoN1kW+WBuCb8l2BSVrznY0x0lgetADmDaMddCuG9USTli17OrwGgXDx2Jdgq5Z7BjlD root@debian-2gb-tor1-01"
}

// to print instance ips:
// https://www.terraform.io/docs/commands/output.html
output "instance_ips" {
  value = ["${aws_instance.example.*.public_ip}"]
}

output "instance_dns" {
  value = ["${aws_instance.example.*.public_dns}"]
}
