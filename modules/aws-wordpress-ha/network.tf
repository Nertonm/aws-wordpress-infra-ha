# VPC
## Criação da VPC com suporte a DNS e hostnames habilitados e sem IPv6
resource "aws_vpc" "main" {
  ### Intervalo de CIDR da VPC
  cidr_block = var.vpc_cidr

  ### Para permitir resolução de DNS e atribuição de nomes DNS
  enable_dns_support = true
  enable_dns_hostnames = true

  ### Desabilitar IPv6
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = var.vpc_name
  }
}

# Internet Gateway
## Criação do Internet Gateway e associação com a VPC
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Elastic IP for NAT Gateway
## Criação de Elastic IPs para os NAT Gateways
resource "aws_eip" "eip_nat_gw" {

  ### Criação de múltiplos EIPs conforme o número de NAT Gateways
  count = var.nat_gateway_count
  tags = {
    Name = "${var.project_name}-nat-eip-${count.index}"
  }
}

# NAT Gateway creation and Elastic IP allocation
resource "aws_nat_gateway" "nat_gw" {
  ### Criação de múltiplos NAT Gateways conforme o número definido
  count = var.nat_gateway_count

  ### Associação do Elastic IP e Subnet pública correspondente
  allocation_id = aws_eip.eip_nat_gw[count.index].id

  ### Posição do NAT Gateway na Subnet pública correspondente
  subnet_id    = aws_subnet.public_subnets[count.index].id

  tags = {
    Name = "${var.project_name}-nat-gw-${count.index}"
  }

  ### Garante que o NAT Gateway seja criado após o Internet Gateway
  depends_on = [aws_internet_gateway.vpc_igw]
}

# Public Subnets (One for each AZ)
## Criação de subnets públicas em cada zona de disponibilidade
resource "aws_subnet" "public_subnets" {
  ### Número de subnets públicas conforme o número de CIDRs fornecidos
  count = length(var.public_subnets_cidr)

  ### Associação com a VPC, CIDR e zona de disponibilidade
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnets_cidr[count.index]
  availability_zone = var.az[count.index]
  
  ### Habilita a atribuição automática de IP público
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${var.az[count.index]}"
  }
}

# Private Subnets (One for each AZ)
## Criação de subnets privadas em cada zona de disponibilidade
resource "aws_subnet" "private_subnets" {
  ### Número de subnets privadas conforme o número de CIDRs fornecidos
  count = length(var.private_subnets_cidr)

  ### Associação com a VPC, CIDR e zona de disponibilidade
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnets_cidr[count.index]
  availability_zone = var.az[count.index]

  ### Desabilita a atribuição automática de IP público
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-subnet-${var.az[count.index]}"
  }
}

# Public Route Table and Association
## Criação da tabela de rotas pública e associação com as subnets públicas
resource "aws_route_table" "public_route" {
  ### Associação com a VPC
  vpc_id = aws_vpc.main.id

  ### Rota padrão para o Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associação da tabela de rotas pública com cada subnet pública
resource "aws_route_table_association" "public_route_table_assoc" {
  ## Número de associações conforme o número de subnets públicas
  count = length(var.public_subnets_cidr)

  ## Associação da tabela de rotas com a subnet pública correspondente
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route.id
}

# Private Route Table and Association
## Criação da tabela de rotas privada e associação com as subnets privadas
resource "aws_route_table" "private_route" {
  ### Associação com a VPC
  vpc_id = aws_vpc.main.id

  ### Número de tabelas de rotas privadas conforme o número de subnets privadas
  count = length(var.private_subnets_cidr)

  ### Rota padrão para o NAT Gateway correspondente, se houver NAT Gateways
  dynamic "route" {
    #### Itera sobre um array de 1 elemento se nat_gateway_count > 0, ou um array vazio caso contrário
    for_each = var.nat_gateway_count > 0 ? [1] : []

    #### Rota padrão para o NAT Gateway correspondente
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat_gw[count.index % var.nat_gateway_count].id
    }
  }

  tags = {
    Name = "${var.project_name}-private-rt-${var.az[count.index]}"
  }
}

# Associação da tabela de rotas privada com cada subnet privada
resource "aws_route_table_association" "private_route_table_assoc" {
  ## Número de associações conforme o número de subnets privadas
  count = length(var.private_subnets_cidr)

  ## Associação da tabela de rotas com a subnet privada correspondente
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route[count.index].id
}

