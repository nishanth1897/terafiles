provider "aws" {
  region = "ap-south-1" 
}

resource "aws_vpc" "private_vpc_1" {
  cidr_block = "10.0.0.0/16" 

tags = {
    Name = "private-VPC1"
  }
}

resource "aws_vpc" "private_vpc_2" {
  cidr_block = "10.1.0.0/16" 

tags = {
    Name = "private-VPC2"
  }
}

resource "aws_vpc" "public_vpc" {
  cidr_block = "10.2.0.0/16"

tags = {
    Name = "public-VPC"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.private_vpc_1.id
  cidr_block = "10.0.1.0/24" 
  availability_zone = "ap-south-1a" 
  map_public_ip_on_launch = true
  tags = {
    Name = "Private-Subnet1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.private_vpc_2.id
  cidr_block = "10.1.1.0/24" 
  availability_zone = "ap-south-1b" 
  map_public_ip_on_launch = true
  tags = {
    Name = "Private-Subnet2"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.public_vpc.id
  cidr_block = "10.2.1.0/24" 
  availability_zone = "ap-south-1a" 
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet"
  }
}

resource "aws_internet_gateway" "public_gateway" {
  vpc_id = aws_vpc.public_vpc.id

  tags = {
    Name = "myigw1"
  }
}

resource "aws_route_table" "private_route_table_1" {
  vpc_id = aws_vpc.private_vpc_1.id

  route {
    cidr_block = aws_vpc.public_vpc.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.public_to_private_1.id
  }

  tags = {
    Name = "Private-routetable1"
  }
}

resource "aws_route_table" "private_route_table_2" {
  vpc_id = aws_vpc.private_vpc_2.id

  route {
    cidr_block = aws_vpc.public_vpc.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.private_1to_private_2.id
  }

  tags = {
    Name = "Private-routetable2"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.public_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_gateway.id
  }

  tags = {
    Name = "Public-routetable"
  }
}

resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table_1.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table_2.id
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "private_sg_1" {
  vpc_id = aws_vpc.private_vpc_1.id

   tags = {
    Name = "private-sg1"
    }

ingress {
    from_port   = 22  
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 0
    to_port     = 65535
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



resource "aws_security_group" "private_sg_2" {
  vpc_id = aws_vpc.private_vpc_2.id
  
   tags = {
    Name = "private-sg2"
    }

ingress {
    from_port   = 22  
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 0
    to_port     = 65535
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


resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.public_vpc.id
   tags = {
    Name = "public-sg"
    }

ingress {
    from_port   = 22  
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 0
    to_port     = 65535
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

resource "aws_instance" "private_instance_1" {
  ami           = "ami-0e670eb768a5fc3d4" 
  instance_type = "t2.micro"     
  subnet_id     = aws_subnet.private_subnet_1.id
  vpc_security_group_ids     = [aws_security_group.private_sg_1.id]
   key_name      = "pvt-key" 
  private_ip    = "10.0.1.10"  
  associate_public_ip_address = false


  tags = {
    Name = "private_Instance1"
  }
}


resource "aws_instance" "private_instance_2" {
  ami           = "ami-0187337106779cdf8" 
  instance_type = "t2.micro"     
  subnet_id     = aws_subnet.private_subnet_2.id
  vpc_security_group_ids     = [aws_security_group.private_sg_2.id]
   key_name      = "pvt-key" 
  private_ip    = "10.1.1.30"  
  associate_public_ip_address = false


  tags = {
    Name = "private_Instance2"
  }
}

resource "aws_instance" "public_instance" { 
  ami           = "ami-0e159fc62d940d348" 
  instance_type = "t2.micro" 
  subnet_id     = aws_subnet.public_subnet.id
  availability_zone      = "ap-south-1a"
  key_name      = "alb" 
  vpc_security_group_ids = [aws_security_group.public_sg.id]

  tags = {
    Name = "public_instance"
  }
}

resource "aws_vpc_peering_connection" "public_to_private_1" {
  vpc_id         = aws_vpc.public_vpc.id
  peer_vpc_id    = aws_vpc.private_vpc_1.id
  auto_accept    = true


tags = {
    Name = "my peering1"
  }
}  


resource "aws_vpc_peering_connection" "private_1to_private_2" {
  vpc_id         = aws_vpc.private_vpc_1.id
  peer_vpc_id    = aws_vpc.private_vpc_2.id
  auto_accept    = true

tags = {
    Name = "my peering2"
  }
}