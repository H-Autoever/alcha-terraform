# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-iot-msk-team-alcha"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = var.public_subnet_names[count.index]
    Type = "Public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = var.private_subnet_names[count.index]
    Type = "Private"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "nat-eip-team-alcha-${count.index + 1}"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = length(var.public_subnet_cidrs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat-gateway-team-alcha-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "rt-public-team-alcha"
  }
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "rt-private-team-alcha-${count.index + 1}"
  }
}

# Route Table Associations - Public
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Group for MSK
resource "aws_security_group" "msk" {
  name_prefix = "msk-sg-team-alcha-"
  description = "Security group for MSK cluster team-alcha"
  vpc_id      = aws_vpc.main.id

  # SCRAM-SHA-512 port for EC2 access
  ingress {
    description     = "MSK SCRAM-SHA-512"
    from_port       = 9096
    to_port         = 9096
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # SCRAM-SHA-512 port for internal MSK communication
  ingress {
    description = "MSK SCRAM-SHA-512 Internal"
    from_port   = 9096
    to_port     = 9096
    protocol    = "tcp"
    self        = true
  }

  # Zookeeper port for EC2 access
  ingress {
    description     = "Zookeeper"
    from_port       = 2181
    to_port         = 2181
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # Zookeeper port for internal MSK communication
  ingress {
    description = "Zookeeper Internal"
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    self        = true
  }

  # SSL port for EC2 access
  ingress {
    description     = "MSK SSL"
    from_port       = 9094
    to_port         = 9094
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # SSL port for internal MSK communication
  ingress {
    description = "MSK SSL Internal"
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    self        = true
  }

  # Plaintext port for EC2 access (for debugging if needed)
  ingress {
    description     = "MSK Plaintext"
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # Plaintext port for internal MSK communication
  ingress {
    description = "MSK Plaintext Internal"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "msk-sg-team-alcha"
  }
}

# Security Group for EC2
resource "aws_security_group" "ec2" {
  name_prefix = "ec2-sg-team-alcha-"
  description = "Security group for EC2 consumer team-alcha"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 실제 환경에서는 특정 IP로 제한
  }

  # Kafka UI access
  ingress {
    description = "Kafka UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg-team-alcha"
  }
}


# Security Group for EKS Cluster
resource "aws_security_group" "eks_cluster" {
  name_prefix = "eks-cluster-sg-team-alcha-"
  description = "Security group for EKS cluster team-alcha"
  vpc_id      = aws_vpc.main.id

  # EKS API Server access (HTTPS)
  ingress {
    description = "EKS API Server"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
  }

  # HTTP for ALB
  ingress {
    description = "HTTP for ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS for ALB
  ingress {
    description = "HTTPS for ALB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "eks-cluster-sg-team-alcha"
    Environment = "kubernetes"
  }
}

# Security Group for EKS Node Group (Workers)
resource "aws_security_group" "eks_nodes" {
  name_prefix = "eks-nodes-sg-team-alcha-"
  description = "Security group for EKS worker nodes team-alcha"
  vpc_id      = aws_vpc.main.id

  # All traffic from cluster
  ingress {
    description     = "All traffic from EKS cluster"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  # Node port range
  ingress {
    description = "Node port range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    self        = true
  }

  # Pod communication
  ingress {
    description = "EKS POD communications"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Kubernetes API Server
  ingress {
    description     = "Permission for Kubernetes API Server"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  # HTTPS egress
  egress {
    description = "All outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP egress
  egress {
    description = "All outbound HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API Server
  egress {
    description     = "Kubernetes API Server"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  # DNS
  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS (UDP)
  egress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "eks-nodes-sg-team-alcha"
    Environment = "kubernetes"
  }
}

# Security Group for ALB (Application Load Balancer)
resource "aws_security_group" "alb" {
  name_prefix = "alb-sg-team-alcha-"
  description = "Security group for ALB team-alcha"
  vpc_id      = aws_vpc.main.id

  # HTTP from anywhere
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS from anywhere
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "alb-sg-team-alcha"
    Environment = "kubernetes"
  }
}