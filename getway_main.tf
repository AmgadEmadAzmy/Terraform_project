resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.lb.id
  subnet_id     = var.nat_subnet_id

  tags = {
    Name = var.nat_name
  }

  depends_on = [ var.nat_depends_on ]
}


resource "aws_eip" "lb" {
}

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = var.internet_vpc_id
  tags = {
    Name = var.internet_gw_name
  }
}