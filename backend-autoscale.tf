resource "aws_autoscaling_group" "three-tier-web-asg" {
  name                 = "three-tier-web-asg"
  launch_configuration = aws_launch_configuration.three-tier-web-lconfig.id
  vpc_zone_identifier  = [ aws_subnet.three-tier-pvt-sub-1.id, aws_subnet.three-tier-pvt-sub-2.id ]
  min_size             = 2
  max_size             = 3
  desired_capacity     = 2
}

resource "aws_launch_configuration" "three-tier-web-lconfig" {
  name_prefix     = "three-tier-web-lconfig"
  image_id        = "ami-0e593d2b811299b15"
  instance_type   = "t2.micro"
  key_name = "three-tier-web-asg-kp"
  security_groups = [ aws_security_group.three-tier-ec2-asg-sg.id ]
  user_data = <<-EOF
                                #!/bin/bash

                                sudo yum install mysql -y

                                EOF
  associate_public_ip_address = false
  lifecycle {
    prevent_destroy = false
  }
  
  }