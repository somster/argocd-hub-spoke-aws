# ----------------------
# Network structure is pre-defined. Here we reference that structure
# -----------------------
data "aws_vpc" "main_vpc" {
  filter {
    name = "tag:Environment"
    values = [upper(var.environment)]
  }
}


data "aws_subnet" "core" {
  for_each          = toset(local.azs)
  vpc_id            = data.aws_vpc.main_vpc.id
  availability_zone = each.value
  filter {
    name   = "tag:Name"
    values = ["owd-${var.environment}_${substr(each.value, -1, -1)}_core"]
  }
}

data "aws_subnet" "dmz" {
  for_each          = toset(local.azs)
  vpc_id            = data.aws_vpc.main_vpc.id
  availability_zone = each.value
  filter {
    name   = "tag:Name"
    values = ["owd-${var.environment}_${substr(each.value, -1, -1)}_dmz"]
  }
}

# data "aws_nat_gateway" "main_vpc" {
#   for_each = toset(local.azs)
#   state = "available"
#   tags = {
#     Name = "OWD-${var.environment}-${substr(each.value, -1, -1)}"
#   }
# }
