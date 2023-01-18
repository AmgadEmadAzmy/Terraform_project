resource "aws_subnet" "subnet" {
    cidr_block = var.subnet_cidr_block
    vpc_id = var.sub_vpc_id
    availability_zone_id = var.sub_availability_zone_id
    tags = {
        Name = var.subnet_name
    }
}