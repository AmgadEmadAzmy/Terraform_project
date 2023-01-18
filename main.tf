module "dev-vpc" {
  source = "./vpc"
  vpc_cider = "10.0.0.0/16"
  vpc_name = "dev-vpc"
}


module "private_subnet_01" {
  source = "./subnet"
  #resource_count = 1
  subnet_cidr_block = "10.0.1.0/24"
  sub_availability_zone_id = "euw1-az1"
  subnet_name = "private_subnet_01"
  sub_vpc_id = module.dev-vpc.vpc_id
}

module "private_subnet_02" {
  source = "./subnet"
  #resource_count = 1
  subnet_cidr_block = "10.0.3.0/24"
  sub_availability_zone_id = "euw1-az2"
  subnet_name = "private_subnet_02"
  sub_vpc_id = module.dev-vpc.vpc_id
}

module "public_subnet_01" {
  source = "./subnet"
  #resource_count = 1
  subnet_cidr_block = "10.0.0.0/24"
  sub_availability_zone_id = "euw1-az1"
  subnet_name = "public_subnet_01"
  sub_vpc_id = module.dev-vpc.vpc_id
}

module "public_subnet_02" {
  source = "./subnet"
  #resource_count = 1
  subnet_cidr_block = "10.0.2.0/24"
  sub_availability_zone_id = "euw1-az2"
  subnet_name = "public_subnet_02"
  sub_vpc_id = module.dev-vpc.vpc_id
}

module "internet_gateway" {
  source = "./internetgateway"
  internet_gw_name = "my_internet_gateway"
  internet_vpc_id = module.dev-vpc.vpc_id
}

module "nat_gateway" {
  source = "./natgateway"
  nat_name = "my_nat_gateway"
  nat_subnet_id = module.public_subnet_01.subnet_id
  nat_depends_on = module.internet_gateway
}

module "public_route_table" {
  source = "./routetable"
  table_name = "public_table"
  table_vpc_id = module.dev-vpc.vpc_id
  table_destination_cidr_block = "0.0.0.0/0"
  table_gateway_id = module.internet_gateway.internet_gw_id
  table_subnet_id = { id1 = module.public_subnet_02.subnet_id, id2 = module.public_subnet_01.subnet_id }
  depends_on = [
    module.public_subnet_01.subnet_id,
    module.private_subnet_02.subnet_id
  ]
}

module "private_route_table" {
  source = "./routetable"
  table_name = "private_table"
  table_vpc_id = module.dev-vpc.vpc_id
  table_destination_cidr_block = "0.0.0.0/0"
  table_gateway_id = module.nat_gateway.nat_gw_id
  table_subnet_id = {id1 = module.private_subnet_02.subnet_id, id2 = module.private_subnet_01.subnet_id }
}

module "security_group" {
  source = "./securitygroup"
  secgr_name = "test"
  secgr_description = "test"
  secgr_vpc_id = module.dev-vpc.vpc_id
  secgr_from_port_in = 22
  secgr_to_port_in = 80
  secgr_protocol_in = "tcp"
  secgr_cider = ["0.0.0.0/0"]
  secgr_from_port_eg = 0
  secgr_to_port_eg = 0
  secgr_protocol_eg = "-1"
}

module "ec2_public_01" {
  source = "./ec2"
  ec2_ami_id = "ami-026e72e4e468afa7b"
  ec2_instance_type = "t2.micro"
  ec2_name = "ec2_public_01"
  ec2_public_ip = true
  ec2_subnet_ip = module.public_subnet_01.subnet_id
  ec2_security_gr = [ module.security_group.secgr_id ]
  ec2_key_name = "terraform"
  ec2_connection_type = "ssh"
  ec2_connection_user = "ubuntu"
  ec2_connection_private_key = "./terraform.pem"
  ec2_provisioner_file_source = "./apache.sh"
  ec2_provisioner_file_destination = "/tmp/apache.sh"
  ec2_provisioner_inline = [ "chmod 777 /tmp/apache.sh", "/tmp/apache.sh ${module.lb_private.lb_public_dns}" ]
  depends_on = [
    module.public_subnet_01.subnet_id,
    module.public_route_table.route_table_id,
    module.lb_private.lb_public_dns
  ]
}

module "ec2_public_02" {
  source = "./ec2"
  ec2_ami_id = "ami-026e72e4e468afa7b"
  ec2_instance_type = "t2.micro"
  ec2_name = "ec2_public_02"
  ec2_public_ip = true
  ec2_subnet_ip = module.public_subnet_02.subnet_id
  ec2_security_gr = [ module.security_group.secgr_id ]
  ec2_key_name = "terraform"
  ec2_connection_type = "ssh"
  ec2_connection_user = "ubuntu"
  ec2_connection_private_key = "./terraform.pem"
  ec2_provisioner_file_source = "./apache.sh"
  ec2_provisioner_file_destination = "/tmp/apache.sh"
  ec2_provisioner_inline = [ "chmod 777 /tmp/apache.sh", "/tmp/apache.sh ${module.lb_private.lb_public_dns}" ]
  depends_on = [
    module.public_subnet_02.subnet_id,
    module.public_route_table.route_table_id,
    module.lb_private.lb_public_dns
  ]
}

module "ec2_private_02" {
  source = "./private_ec2"
  ec2_ami_id = "ami-026e72e4e468afa7b"
  ec2_instance_type = "t2.micro"
  ec2_name = "ec2_private_02"
  ec2_subnet_ip = module.private_subnet_02.subnet_id
  ec2_security_gr = [ module.security_group.secgr_id ]
  ec2_key_name = "terraform"
}


module "ec2_private_01" {
  source = "./private_ec2"
  ec2_ami_id = "ami-026e72e4e468afa7b"
  ec2_instance_type = "t2.micro"
  ec2_name = "ec2_private_01"
  ec2_subnet_ip = module.private_subnet_01.subnet_id
  ec2_security_gr = [ module.security_group.secgr_id ]
  ec2_key_name = "terraform"
}

lb_name = "lbpublic"
  lb_internal = false
  lb_type = "application"
  lb_security_group = [ module.security_group.secgr_id ]
  lb_subnet = [ module.public_subnet_01, module.public_subnet_02 ]

  listener_port = "80"
  listener_protocol = "HTTP"
  listener_type = "forward"

  depends_on = [
    module.dev-vpc,
    module.ec2_public_01,
    module.ec2_public_02,
    module.public_subnet_01,
    module.public_subnet_02
  ]

}