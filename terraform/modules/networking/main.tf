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
    Name = "igw-iot-msk-team-carpoor"
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
    Name = "nat-eip-team-carpoor-${count.index + 1}"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = length(var.public_subnet_cidrs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat-gateway-team-carpoor-${count.index + 1}"
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
    Name = "rt-public-team-carpoor"
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
    Name = "rt-private-team-carpoor-${count.index + 1}"
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
  name_prefix = "msk-sg-team-carpoor-"
  description = "Security group for MSK cluster team-carpoor"
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
    Name = "msk-sg-team-carpoor"
  }
}

# Security Group for EC2
resource "aws_security_group" "ec2" {
  name_prefix = "ec2-sg-team-carpoor-"
  description = "Security group for EC2 consumer team-carpoor"
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
    Name = "ec2-sg-team-carpoor"
  }
}
