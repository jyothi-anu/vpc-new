resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = local.vpc_final_tags
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = local.igw_final_tags
}

resource "aws_subnet" "public" {
  vpc_id                = aws_vpc.main.id
  count                 = length(var.public_subnet_cidr)
  cidr_block            = var.public_subnet_cidr[count.index]
  availability_zone   = local.az_names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      #robo-dev-public-us-east-1a
      Name = "${var.project}-${var.environment}-public-${local.az_names[count.index]}"
    },
    var.public_subnet_tags
  )

}
resource "aws_subnet" "private" {
  vpc_id                = aws_vpc.main.id
  count                 = length(var.private_subnet_cidr)
  cidr_block            = var.private_subnet_cidr[count.index]
  availability_zone   = local.az_names[count.index]

  tags = merge(
    local.common_tags,
    {
      #robo-dev-private-us-east-1a
      Name = "${var.project}-${var.environment}-private-${local.az_names[count.index]}"
    },
    var.private_subnet_tags
  )

}
resource "aws_subnet" "database" {
  vpc_id                = aws_vpc.main.id
  count                 = length(var.database_subnet_cidr)
  cidr_block            = var.database_subnet_cidr[count.index]
  availability_zone   = local.az_names[count.index]

  tags = merge(
    local.common_tags,
    {
      #robo-dev-database-us-east-1a
      Name = "${var.project}-${var.environment}-database-${local.az_names[count.index]}"
    },
    var.database_subnet_tags
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = local.final_public_route_table_tags
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = local.final_private_route_table_tags
}
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = local.final_database_route_table_tags
}

#aws route to public attach internat gateaway
resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.main.id
}
#allocate eip 
resource "aws_eip" "nat" {
  domain   = "vpc"

  tags = local.final_eip_tags
}
#creating nat gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = local.final_nat_gateway_tags
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}
resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_nat_gateway.main.id

}
resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_nat_gateway.main.id
}
#route table association
resource "aws_route_table_association" "public" {
  count            = length(var.public_subnet_cidr)
  subnet_id        = aws_subnet.public[count.index].id
  route_table_id   = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count            = length(var.private_subnet_cidr)
  subnet_id        = aws_subnet.private[count.index].id
  route_table_id   = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count            = length(var.database_subnet_cidr)
  subnet_id        = aws_subnet.database[count.index].id
  route_table_id   = aws_route_table.database.id
}