variable "ec2_ami_id" {
}

variable "ec2_instance_type" {
}

variable "ec2_subnet_ip" {
}

variable "ec2_security_gr" {
}

variable "user_data" {
  default = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx
    sudo chmod 777 /var/www/html
    sudo chmod 777 /var/www/html/index.nginx-debian.html
    sudo echo "<h1>Hello World! - Nathan from EC2 private</h1>" > /var/www/html/index.nginx-debian.html
    sudo systemctl restart nginx
  EOF
}

variable "ec2_name" {
}

variable "ec2_key_name" {
}