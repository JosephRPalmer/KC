provider "aws" {
  version = "~> 3.0"
  region  = "eu-west-1"
}

resource "tls_private_key" "new-keypair" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "klynveld_key" {
  key_name   = "klynveld-keypair"
  public_key = "${tls_private_key.new-keypair.public_key_openssh}"
}

resource "aws_vpc" "klynveld_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.klynveld_vpc.id
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.klynveld_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public"
  }
}
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.klynveld_vpc.id
  cidr_block = "10.0.129.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "Private"
  }
}

resource "aws_route_table" "public_routes" {
  vpc_id = aws_vpc.klynveld_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "Public Routing"
  }
}

resource "aws_route_table_association" "public_routes_to_table" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_routes.id
}

resource "aws_route_table" "private_routes" {
  vpc_id = aws_vpc.klynveld_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "Private Routing"
  }
}

resource "aws_eip" "ng-eip" {
vpc      = true
}
resource "aws_nat_gateway" "nat_gateway" {
allocation_id = aws_eip.ng-eip.id
subnet_id = aws_subnet.public.id
}


resource "aws_route_table_association" "private_routes_to_table" {
    subnet_id = aws_subnet.private.id
    route_table_id = aws_route_table.private_routes.id
}

resource "aws_security_group" "web-sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.klynveld_vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0 
    to_port     = 0 
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "back-sg" {
  name   = "back-sg"
  vpc_id = aws_vpc.klynveld_vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    security_groups = [aws_security_group.web-sg.id]
  }

   ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion-sg.id]
  }


  egress {
    protocol    = -1
    from_port   = 0 
    to_port     = 0 
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion-sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.klynveld_vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0 
    to_port     = 0 
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_instance" "web-server" {
  count                       = 5
  ami                         = "ami-0b5247d4d01653d09"
  key_name                    = aws_key_pair.klynveld_key.key_name
  instance_type               = "t2.micro"
  security_groups             = ["${aws_security_group.web-sg.name}"]
  subnet_id                   = aws_subnet.public.id
}



resource "aws_instance" "backend-server" {
  count                       = 10
  ami                         = "ami-0b5247d4d01653d09"
  key_name                    = aws_key_pair.klynveld_key.key_name
  instance_type               = "t2.micro"
  security_groups             = ["${aws_security_group.back-sg.name}"]
  subnet_id                   = aws_subnet.private.id
}


resource "aws_instance" "bastion-server" {
  ami                         = "ami-0b5247d4d01653d09"
  key_name                    = aws_key_pair.klynveld_key.key_name
  instance_type               = "t2.micro"
  security_groups             = ["${aws_security_group.bastion-sg.name}"]
  subnet_id                   = aws_subnet.public.id
}

