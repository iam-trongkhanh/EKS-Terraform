# ============================================================================
# VPC
# ============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# ============================================================================
# INTERNET GATEWAY (if public subnets are enabled)
# ============================================================================

resource "aws_internet_gateway" "main" {
  count = var.enable_public_subnets ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

# ============================================================================
# PUBLIC SUBNETS
# ============================================================================

resource "aws_subnet" "public" {
  count = var.enable_public_subnets ? length(var.availability_zones) : 0

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-${var.availability_zones[count.index]}"
      Type = "public"
    }
  )
}

# ============================================================================
# PRIVATE SUBNETS
# ============================================================================

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name                              = "${var.name}-private-${var.availability_zones[count.index]}"
      Type                              = "private"
      "kubernetes.io/role/internal-elb" = "1"
    }
  )
}

# ============================================================================
# ELASTIC IPs FOR NAT GATEWAYS
# ============================================================================

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway && var.enable_public_subnets ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ============================================================================
# NAT GATEWAYS
# ============================================================================

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway && var.enable_public_subnets ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ============================================================================
# ROUTE TABLES
# ============================================================================

# Public route table
resource "aws_route_table" "public" {
  count = var.enable_public_subnets ? 1 : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-rt"
    }
  )
}

# Public route table associations
resource "aws_route_table_association" "public" {
  count = var.enable_public_subnets ? length(var.availability_zones) : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Private route tables
resource "aws_route_table" "private" {
  count = var.enable_nat_gateway && var.enable_public_subnets ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  # Add NAT Gateway route if NAT is enabled and public subnets exist
  dynamic "route" {
    for_each = var.enable_nat_gateway && var.enable_public_subnets ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-rt-${count.index + 1}"
    }
  )
}

# Private route table associations
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.enable_nat_gateway && var.enable_public_subnets ? (
    var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
  ) : aws_route_table.private[count.index].id
}

