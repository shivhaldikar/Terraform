# Web Server Setup
# Note: Create a key pair under EC2/KeyPair
# 
# 1. Create vpc
# 2. Create Internet Gateway
# 3. Create Custom Route Table
# 4. Create Subnet
# 5. Associate Subnet with Route Table
# 6. Create Security Group to allow port 22,80,443
# 7. Create Network Interface with an IP in the subnet 
# 8. Assign an elastic IP to the Network Interface
# 9. Create Ubuntu server abd install/enable apache2

variable "access_info" {
   description = "Provider key and secret"
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.access_info.access_key
  secret_key = var.access_info.secret_key
}

# 1. Create vpc
resource "aws_vpc" "web-server-vpc-1" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "development-webserver"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "web-server-internet-gateway-1" {
  vpc_id = aws_vpc.web-server-vpc-1.id
  tags = {
    "Name" = "development-webserver"
  }
}

# 3. Create Custom Route Table
resource "aws_route_table" "web-server-route-table-1" {
  vpc_id = aws_vpc.web-server-vpc-1.id
  route = [ {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web-server-internet-gateway-1.id
    carrier_gateway_id = null
    destination_prefix_list_id = null
    egress_only_gateway_id = null
    instance_id = null
    ipv6_cidr_block = null
    local_gateway_id = null
    nat_gateway_id = null
    network_interface_id = null
    transit_gateway_id = null
    vpc_endpoint_id = null
    vpc_peering_connection_id = null
  } ]

  tags = {
    "Name" = "development-webserver"
  }
}

# 4. Create Subnet
resource "aws_subnet" "web-server-subnet-1" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.web-server-vpc-1.id
  availability_zone = "us-east-1a"
  tags = {
    "Name" = "development-subnet"
  }
}

# 5. Associate Subnet with Route Table
resource "aws_route_table_association" "web-server-route-table-to-subnet1" {
  subnet_id      = aws_subnet.web-server-subnet-1.id
  route_table_id = aws_route_table.web-server-route-table-1.id
}

# 6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "web-server-security-group-1" {
  name        = "allow web traffic"
  description = "allow web traffic 22, 80 and 443"
  vpc_id      = aws_vpc.web-server-vpc-1.id

  ingress = [{
    cidr_blocks     = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description     = "HTTPS"
    from_port       = 443
    protocol        = "tcp"
    to_port         = 443
    security_groups = null
    self            = null
    prefix_list_ids = null
    },
    {
      cidr_blocks     = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      description     = "HTTP"
      from_port       = 80
      protocol        = "tcp"
      to_port         = 80
      security_groups = null
      self            = null
      prefix_list_ids = null
    },
    {
      cidr_blocks     = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      description     = "FTP"
      from_port       = 22
      protocol        = "tcp"
      to_port         = 22
      security_groups = null
      self            = null
      prefix_list_ids = null
  }]

  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "All"
    from_port        = 0
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids  = null
    protocol         = "-1"
    security_groups  = null
    self             = null
    to_port          = 0
  }]
  tags = {
    "Name" = "development-webserver"
  }
}

# 7. Create Network Interface with an IP in the subnet 
resource "aws_network_interface" "web-server-network-interface1" {
  subnet_id       = aws_subnet.web-server-subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.web-server-security-group-1.id]

  tags = {
    "Name" = "development-network-interface"
  }

}

# 8. Assign an elastic IP to the Network Interface
# don't forget to add internet gateway depenencies
resource "aws_eip" "web-server-public-ip1" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-network-interface1.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.web-server-internet-gateway-1
  ]

  tags = {
    "Name" = "development-public-ip1"
  }

}

# 9. Create Ubuntu server abd install/enable apache2
resource "aws_instance" "web-server-ubuntu1" {
  ami               = "ami-09e67e426f25ce0d7"
  availability_zone = "us-east-1a"
  instance_type     = "t2.micro"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-network-interface1.id
  }

  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install apache2 -y
  sudo systemctl start apache2
  sudo bash -c 'echo Welcome to Web-Server-1! > /var/www/html/index.html'
  EOF

  tags = {
    "Name" = "development-ubuntu-instance-1"
    "Type" = "web-server"
  }
}

output "public_ip" {
  value = aws_eip.web-server-public-ip1.public_ip
}
