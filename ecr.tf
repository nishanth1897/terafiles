provider "aws" {
  region = "ap-south-1" 
}

resource "aws_vpc" "public_vpc" {
  cidr_block = "10.2.0.0/16"

tags = {
    Name = "public-VPC"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.public_vpc.id
  cidr_block = "10.2.1.0/24" 
  availability_zone = "ap-south-1a" 
  map_public_ip_on_launch = true
  tags = {
    Name = "Private-Subnet1"
  }
}

resource "aws_subnet" "public_subnet" {                                                 
  vpc_id     = aws_vpc.public_vpc.id
  cidr_block = "10.2.2.0/24" 
  availability_zone = "ap-south-1a" 
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet"
  }
}

resource "aws_subnet" "public_subnet_1" {                                                   
  vpc_id     = aws_vpc.public_vpc.id
  cidr_block = "10.2.3.0/24" 
  availability_zone = "ap-south-1b" 
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet1"
  }
}


resource "aws_internet_gateway" "public_gateway" {
  vpc_id = aws_vpc.public_vpc.id

  tags = {
    Name = "myigw1"
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

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "nat-gateway"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.public_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "private_sg_1" {
  vpc_id = aws_vpc.public_vpc.id

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
  ami           = "ami-0e4fd655fb4e26c30" 
  instance_type = "t2.micro"     
  subnet_id     = aws_subnet.private_subnet_1.id
  vpc_security_group_ids     = [aws_security_group.private_sg_1.id]
   key_name      = "pvt-key" 
  private_ip    = "10.2.1.50"  
  associate_public_ip_address = false


  tags = {
    Name = "private_Instance1"
  }
}  

resource "aws_instance" "public_instance" { 
  ami           = "ami-06241a48581be8fa2" 
  instance_type = "t2.micro" 
  subnet_id     = aws_subnet.public_subnet.id
  availability_zone      = "ap-south-1a"
  key_name      = "alb" 
  vpc_security_group_ids = [aws_security_group.public_sg.id]

  tags = {
    Name = "public_instance"
  }
}

resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.private_sg_1.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_1.id]

  enable_deletion_protection = false

  enable_http2               = true
  idle_timeout               = 60
  enable_cross_zone_load_balancing = true
}


resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.public_vpc.id

  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}

