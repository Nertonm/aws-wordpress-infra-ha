resource "aws_lb" "main" {
    name = "${var.project_name}-alb-${var.environment}"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.lb_sg.id]
    subnets = aws_subnet.public_subnets[*].id
    tags = {
        Name = "${var.project_name}-alb-${var.environment}"
    }
}

resource "aws_alb_target_group" "main" {
    name = "${var.project_name}-tg-${var.environment}"
    port = 80
    protocol = "HTTP"
    target_type = "instance"
    vpc_id = aws_vpc.main.id

    health_check {
      enabled = true
      path = "/wp-admin/install.php"
      protocol = "HTTP"
      matcher = "200-399"

      timeout = var.alb_timeout
      interval = var.alb_interval
      healthy_threshold = var.alb_healthy_threshold
      unhealthy_threshold = var.alb_unhealthy_threshold
    }
  
  tags = {
      Name = "${var.project_name}-tg-${var.environment}"
    }
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.main.arn
    port = "80"
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_alb_target_group.main.arn
    }
}