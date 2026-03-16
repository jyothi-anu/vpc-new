locals {
  common_tags = {
        project      = var.project
        environment  = var.environment
        terraform    = true
  }
  vpc_final_tags = merge(
    {
        Name = "${var.project}-${var.environment}"
    },
    local.common_tags,
    var.vpc_tags
  )
  igw_final_tags = merge(
    {
        Name = "${var.project}-${var.environment}"
    },
    local.common_tags,
    var.igw_tags
  )
  az_names = slice(data.aws_availability_zones.available.names,0,2)
  final_public_route_table_tags = merge(
    {
      Name = "${var.project}-${var.environment}-public"
    },
    local.common_tags,
    var.public_route_table_tags
  )
   final_private_route_table_tags = merge(
    {
      Name = "${var.project}-${var.environment}-private"
    },
    local.common_tags,
    var.private_route_table_tags
  )
   final_database_route_table_tags = merge(
    {
      Name = "${var.project}-${var.environment}-database"
    },
    local.common_tags,
    var.database_route_table_tags
  )
  final_eip_tags = merge(
    {
      Name = "${var.project}-${var.environment}"
    },
    local.common_tags,
    var.eip_tags
  )
  final_nat_gateway_tags = merge(
    {
      Name = "${var.project}-${var.environment}"
    },
    local.common_tags,
    var.nat_gateway_tags
  )
}