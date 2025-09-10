# AWS Application Load Balancer (ALB) Configuration for WordPress HA
## Cria um ALB para WordPress HA com target group e listener HTTP
resource "aws_lb" "main" {
    name = "${var.project_name}-alb-${var.environment}"
    
    ### Voltado para internet
    internal = false
    
    ### Application Load Balancer
    load_balancer_type = "application"

    ### Configurações de segurança e subnets
    security_groups = [aws_security_group.lb_sg.id]
    subnets = aws_subnet.public_subnets[*].id
    tags = {
        Name = "${var.project_name}-alb-${var.environment}"
    }
}

# Target Group para o ALB
resource "aws_alb_target_group" "main" {
    name = "${var.project_name}-tg-${var.environment}"
    ## Configuração do target group
    port = var.alb_port
    protocol = var.alb_protocol
    target_type = "instance"
    vpc_id = aws_vpc.main.id

    ## Configuração do health check
    health_check {
      enabled = true

      ### Path para o health check
      path = var.alb_path

      ### Protocolo a ser usado no health check
      protocol = var.alb_protocol
      
      ### Status code esperado para considerar o alvo saudável
      matcher = var.alb_matcher

      ### Tempo limite para o health check
      timeout = var.alb_timeout

      ### Intervalo entre os health checks
      interval = var.alb_interval

      ### Número de tentativas bem-sucedidas para considerar o alvo saudável
      healthy_threshold = var.alb_healthy_threshold

      ### Número de tentativas malsucedidas para considerar o alvo não saudável
      unhealthy_threshold = var.alb_unhealthy_threshold
    }
  
  tags = {
      Name = "${var.project_name}-tg-${var.environment}"
    }
}

# Listener HTTP para o ALB
resource "aws_lb_listener" "http" {
    ## Configuração do listener HTTP
    load_balancer_arn = aws_lb.main.arn
    port = var.alb_port
    protocol = var.alb_protocol

    ## Ação padrão do listener
    default_action {
      type = "forward"
      target_group_arn = aws_alb_target_group.main.arn
    }
}