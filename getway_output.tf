output "nat_gw_id" {
  value = aws_nat_gateway.nat_gateway.id
}

output "elistic_ip" {
  value = aws_eip.lb.id
}
output "internet_gw_id" {
  value = aws_internet_gateway.internet_gw.id
}