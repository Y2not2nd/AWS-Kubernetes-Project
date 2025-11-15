data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names
  public_subnet_map  = { for idx, cidr in var.public_subnets : tostring(idx) => cidr }
  private_subnet_map = { for idx, cidr in var.private_subnets : tostring(idx) => cidr }
}

resource "aws_vpc" "yasn" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "yasn-vpc"
  })
}

resource "aws_internet_gateway" "yasn" {
  vpc_id = aws_vpc.yasn.id

  tags = merge(var.tags, {
    Name = "yasn-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = local.public_subnet_map

  vpc_id                  = aws_vpc.yasn.id
  cidr_block              = each.value
  availability_zone       = element(local.azs, tonumber(each.key))
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "yasn-public-${each.key}"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnet_map

  vpc_id            = aws_vpc.yasn.id
  cidr_block        = each.value
  availability_zone = element(local.azs, tonumber(each.key))

  tags = merge(var.tags, {
    Name = "yasn-private-${each.key}"
  })
}

resource "aws_eip" "nat" {
  vpc = true

  tags = merge(var.tags, {
    Name = "yasn-nat-eip"
  })
}

resource "aws_nat_gateway" "yasn" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["0"].id

  depends_on = [aws_internet_gateway.yasn]

  tags = merge(var.tags, {
    Name = "yasn-nat"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.yasn.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.yasn.id
  }

  tags = merge(var.tags, {
    Name = "yasn-public-rt"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.yasn.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.yasn.id
  }

  tags = merge(var.tags, {
    Name = "yasn-private-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
