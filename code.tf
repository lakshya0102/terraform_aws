provider "aws" {
  region     = "ap-south-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "pr"
  }
}
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.main.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
    }

  route  {
      ipv6_cidr_block        = "::/0"
      gateway_id = aws_internet_gateway.gw.id
    }
  

}
resource "aws_subnet" "mai" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Ma"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.mai.id
  route_table_id = aws_route_table.example.id
}
resource "aws_security_group" "allow" {
  name        = "allow"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
      description      = "https"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      
    }
    ingress {
      description      = "http"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      
    }
    ingress {
      description      = "ssh"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      
    }
  

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  tags = {
    Name = "allow"
  }
}
resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.mai.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow.id]

  
}
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.test.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}
resource "aws_instance" "instances"{
  ami = "ami-06a0b4e3b7eb7a300"
  instance_type = "t2.micro"
  
  key_name = "lakshya"

  network_interface{
    device_index = 0
    network_interface_id =  aws_network_interface.test.id

  }
  user_data = <<-EOF
              #!/bin/bash
              sudo su
              yum update -y
              yum install httpd -y
              systemctl start httpd
              bash -c 'echo your first web server > /var/www/html/index.html'
              EOF
  tags = {
    Name = "web_server"
  }            
}
