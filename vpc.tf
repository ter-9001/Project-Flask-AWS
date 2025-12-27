# Data to fetch Availability Zones (AZs)
data "aws_availability_zones" "available" {
  state = "available"
}

# 1. EKS VPC Creation
resource "aws_vpc" "eks_vpc" {
  cidr_block             = "193.70.0.0/16"
  enable_dns_support     = true
  enable_dns_hostnames = true
  tags = {
    Name = "EKS-VPC"
    # Tag essencial para EKS e Load Balancers funcionarem
    "kubernetes.io/cluster/flask-project-eks" = "owned"
  }
}

# 2. Create Public Subnets (2 AZs)
resource "aws_subnet" "public_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index)
  map_public_ip_on_launch = true # Necessário para IGW e Load Balancers
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "EKS-Public-Subnet-${count.index + 1}"
    "kubernetes.io/cluster/flask-project-eks" = "owned"
    "kubernetes.io/role/elb" = 1 # Tag para AWS Load Balancer Controller
  }
}

# 3. Create Private Subnets (2 AZs) - Para Worker Nodes
resource "aws_subnet" "private_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.eks_vpc.cidr_block, 8, count.index + 2)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "EKS-Private-Subnet-${count.index + 1}"
    "kubernetes.io/cluster/flask-project-eks" = "owned"
    "kubernetes.io/role/internal-elb" = 1 # Tag para Load Balancer interno, se necessário
  }
}

# 4. Internet Gateway
resource "aws_internet_gateway" "eks_gw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "EKS-GW"
  }
}

# =========================================================================
# CORREÇÃO CRÍTICA: Múltiplos NAT Gateways para garantir o acesso à Internet em todas as AZs
# =========================================================================

# 5. Allocate Elastic IPs (EIP) for each NAT Gateway (1 por AZ)
resource "aws_eip" "nat_gateway_eip" {
  count = 2 # 2 EIPs, um para cada AZ
  depends_on = [aws_internet_gateway.eks_gw]
}

# 6. Create the NAT Gateways (1 por Public Subnet/AZ)
resource "aws_nat_gateway" "eks_nat_gateway" {
  count         = 2 # 2 NAT Gateways
  allocation_id = aws_eip.nat_gateway_eip[count.index].id
  # Cada NAT GW deve estar na Public Subnet da sua respectiva AZ
  subnet_id     = aws_subnet.public_subnets[count.index].id
  depends_on    = [aws_internet_gateway.eks_gw]

  tags = {
    Name = "EKS-NAT-GW-${count.index + 1}"
  }
}

# 7. Create Route Tables for the Private Subnets (2 Tabelas, 1 por AZ)
resource "aws_route_table" "private_route_table" {
  count = 2
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "EKS-Private-Route-Table-${count.index + 1}"
  }
}

# 8. Add the outbound route (0.0.0.0/0) through the correct NAT Gateway
resource "aws_route" "private_internet_route" {
  count = 2
  route_table_id         = aws_route_table.private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  # Roteia para o NAT Gateway na mesma AZ
  nat_gateway_id         = aws_nat_gateway.eks_nat_gateway[count.index].id
}

# 9. Associate the Private Route Tables with the Private Subnets
resource "aws_route_table_association" "private_subnet_association" {
  count = 2
  # Associa a Private Subnet [i] com a Private Route Table [i]
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

# =========================================================================
# Roteamento Público (Não alterado, mas completo para referência)
# =========================================================================

# 10. Route Table for Public Subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "EKS-Public-Route-Table"
  }
}

# 11. Public Subnets Route to Internet Gateway
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_gw.id
}

# 12. Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public_subnet_association_0" {
  subnet_id      = aws_subnet.public_subnets[0].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association_1" {
  subnet_id      = aws_subnet.public_subnets[1].id
  route_table_id = aws_route_table.public_route_table.id
}