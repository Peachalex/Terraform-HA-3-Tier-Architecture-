resource "aws_vpc" "three-tier-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "three-tier-vpc"
    }
}

resource "aws_subnet" "three-tier-pub-sub-1" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.0.0.0/28"
    availability_zone = "us-east-2a"
    map_public_ip_on_launch = "true"

    tags = {
      Name = "three-tier-pub-sub-1"
    }
}

resource "aws_subnet" "three-tier-pub-sub-2" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.0.0.16/28"
    availability_zone = "us-east-2b"
    map_public_ip_on_launch = "true"

    tags = {
      Name = "three-tier-pub-sub-2"
    }
}

resource "aws_subnet" "three-tier-pvt-sub-1" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.0.0.32/28"
    availability_zone = "us-east-2a"
    map_public_ip_on_launch = "false"

    tags = {
      Name = "three-tier-pvt-sub-1"
    }
}

resource "aws_subnet" "three-tier-pvt-sub-2" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.0.0.48/28"
    availability_zone = "us-east-2b"
    map_public_ip_on_launch = "false"

    tags = {
      Name = "three-tier-pvt-sub-2"
    }
}

resource "aws_subnet" "three-tier-pvt-sub-3" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.0.0.64/28"
    availability_zone = "us-east-2a"
    map_public_ip_on_launch = "false"

    tags = {
      Name = "three-tier-pvt-sub-3"
    }
}

resource "aws_subnet" "three-tier-pvt-sub-4" {
    vpc_id = aws_vpc.three-tier-vpc.id
    cidr_block = "10.0.0.80/28"
    availability_zone = "us-east-2b"
    map_public_ip_on_launch = "false"

    tags = {
      Name = "three-tier-pvt-sub-4"
    }
}

resource "aws_internet_gateway" "three-tier-igw" {
  tags = {
    Name = "three-tier-igw"
  }
  vpc_id = aws_vpc.three-tier-vpc.id
}


resource "aws_route_table" "three-tier-web-rt" {
  vpc_id = aws_vpc.three-tier-vpc.id
  tags = {
    Name = "three-tier-web-rt"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.three-tier-igw.id
  }
}

resource "aws_route_table" "three-tier-app-rt" {
  vpc_id = aws_vpc.three-tier-vpc.id
  tags = {
    Name = "three-tier-app-rt"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.three-tier-natgw-01.id
  }
}

resource "aws_route_table_association" "three-tier-rt-as-1" {
  subnet_id      = aws_subnet.three-tier-pub-sub-1.id
  route_table_id = aws_route_table.three-tier-web-rt.id  
}

resource "aws_route_table_association" "three-tier-rt-as-2" {
  subnet_id      = aws_subnet.three-tier-pub-sub-2.id
  route_table_id = aws_route_table.three-tier-web-rt.id  
}

resource "aws_route_table_association" "three-tier-rt-as-3" {
  subnet_id      = aws_subnet.three-tier-pvt-sub-1.id
  route_table_id = aws_route_table.three-tier-app-rt.id  
}

resource "aws_route_table_association" "three-tier-rt-as-4" {
  subnet_id      = aws_subnet.three-tier-pvt-sub-2
  route_table_id = aws_route_table.three-tier-app-rt.id  
}

resource "aws_route_table_association" "three-tier-rt-as-5" {
  subnet_id      = aws_subnet.three-tier-pvt-sub-3
  route_table_id = aws_route_table.three-tier-app-rt.id  
}

resource "aws_route_table_association" "three-tier-rt-as-6" {
  subnet_id      = aws_subnet.three-tier-pvt-sub-4.id
  route_table_id = aws_route_table.three-tier-app-rt.id  
}

resource "aws_eip" "three-tier-nat-eip" {
   domain = "vpc"
}

resource "aws_nat_gateway" "three-tier-natgw-01" {
  allocation_id = aws_eip.three-tier-nat-eip.id
  subnet_id     = aws_subnet.three-tier-pub-sub-1.id

  tags = {
    Name = "three-tier-natgw-01"
  }
  depends_on = [ aws_internet_gateway.three-tier-igw ]
}

resource "aws_lb" "three-tier-web-lb" {
  name     = "three-tier-web-lb"
  internal = true
  load_balancer_type = "application"

  security_groups = [aws_security_group.three-tier-alb-sg-1.id] 
  subnets         = [aws_subnet.three-tier-pub-sub-1.id, aws_subnet.three-tier-pub-sub-2.id]

  tags = {
    Environment = "three-tier-web-lb"
  } 
}

resource "aws_lb_target_group" "three-tier-seb-lb-tg" {
  name     = "three-tier-web-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.three-tier-vpc.id

  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }  
}

resource "aws_lb_listener" "three-tier-web-lb-listner" {
  load_balancer_arn = aws_lb.three-tier-web-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.three-tier-seb-lb-tg.arn
    }
}

resource "aws_autoscaling_attachment" "three-tier-web-attach" {
  autoscaling_group_name = aws_autoscaling_group.three-tier-web-asg.name
  lb_target_group_arn = aws_lb_target_group.three-tier-seb-lb-tg.arn
  
}