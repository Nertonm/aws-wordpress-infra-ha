# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support = true
  enable_dns_hostnames = true

  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = var.vpc_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "eip_nat_gw" {
  count = var.nat_gateway_count
  tags = {
    Name = "${var.project_name}-nat-eip-${count.index}"
  }
}

# NAT Gateway creation and Elastic IP allocation
resource "aws_nat_gateway" "nat_gw" {
  count = var.nat_gateway_count
  allocation_id = aws_eip.eip_nat_gw[count.index].id
  subnet_id    = aws_subnet.public_subnets[count.index].id

  tags = {
    Name = "${var.project_name}-nat-gw-${count.index}"
  }

  depends_on = [aws_internet_gateway.vpc_igw]
}

# Public Subnets (One for each AZ)
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnets_cidr)

  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnets_cidr[count.index]
  availability_zone = var.az[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${var.az[count.index]}"
  }
}

# Private Subnets (One for each AZ)
resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnets_cidr)

  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnets_cidr[count.index]
  availability_zone = var.az[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-subnet-${var.az[count.index]}"
  }
}

# Public Route Table and Association
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_route_table_assoc" {
  count = length(var.public_subnets_cidr)

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route.id
}

# Private Route Table and Association
resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.main.id
  count = length(var.private_subnets_cidr)

  dynamic "route" {
    # Itera sobre um array de 1 elemento se nat_gateway_count > 0, ou um array vazio caso contrário
    for_each = var.nat_gateway_count > 0 ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat_gw[count.index % var.nat_gateway_count].id
    }
  }

  tags = {
    Name = "${var.project_name}-private-rt-${var.az[count.index]}"
  }
}

resource "aws_route_table_association" "private_route_table_assoc" {
  count = length(var.private_subnets_cidr)

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route[count.index].id
}

