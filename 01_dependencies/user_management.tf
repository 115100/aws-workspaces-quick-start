resource "aws_instance" "management" {
  instance_type               = "t2.micro"
  ami                         = data.aws_ami.amazon_linux.id
  subnet_id                   = local.subnet_ids[0]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.keypair.key_name

  vpc_security_group_ids = [aws_security_group.management.id]

  depends_on = [aws_directory_service_directory.directory]
  user_data  = <<EOF
#!/bin/env bash

echo "Installing packages"
yum -y install sssd realmd krb5-workstation samba-common-tools expect openldap-clients
# adcli in amazon repo is not recent enough to have passwd-user command
curl -sL https://rpmfind.net/linux/centos/8-stream/BaseOS/x86_64/os/Packages/adcli-0.8.2-12.el8.x86_64.rpm -o /tmp/adcli.rpm
rpm -i /tmp/adcli.rpm

echo "Joining domain ${local.domain_name}"
expect -c "spawn realm join -U administrator@${local.domain_name} ${local.domain_name}; expect \"*?assword for administrator@${local.domain_name}:*\"; send -- \"${var.admin_password}\\r\" ; expect eof"

if [ "${var.auto_create_users}" = "false" ]; then
  exit 0
fi

echo "Creating Users"
${local.create_users_cmd}
${local.set_passwd_cmd}
EOF
}

locals {
  create_users_cmd = join("\n", formatlist(
    "echo '${var.admin_password}' | adcli create-user %s --domain ${local.domain_name} -U Administrator --stdin-password",
  var.users))
  passwd_user_cmd = "echo \\\"${var.admin_password}\\\" | adcli passwd-user %s --domain ${local.domain_name} -U Administrator --stdin-password"
  set_passwd_cmd = join("\n", formatlist(
    "expect -c 'spawn bash -c \"${local.passwd_user_cmd}\"; expect \"*?assword for *\"; send -- \"${var.default_user_password}\\r\"; expect \"eof\"'",
  var.users))
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_security_group_rule" "management_ssh_ipv4" {
  count             = local.provisioner_cidr_ipv4 == null ? 0 : 1
  security_group_id = aws_security_group.management.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  type              = "ingress"
  cidr_blocks       = [ local.provisioner_cidr_ipv4 ]
}

resource "aws_security_group_rule" "management_ssh_ipv6" {
  count             = local.provisioner_cidr_ipv6 == null ? 0 : 1
  security_group_id = aws_security_group.management.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  type              = "ingress"
  ipv6_cidr_blocks = [ local.provisioner_cidr_ipv6 ]
}

resource "aws_security_group_rule" "management_egress" {
  security_group_id = aws_security_group.management.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  type              = "egress"
  cidr_blocks       = [ "0.0.0.0/0" ]
}

resource "aws_security_group" "management" {
  vpc_id = local.vpc_id
}

locals {
  provisioner_ip = chomp(data.http.provisoner_ip.body)
  provisioner_cidr_ipv4 = can(cidrnetmask("${local.provisioner_ip}/32")) ? "${local.provisioner_ip}/32" : null
  provisioner_cidr_ipv6 = !can(cidrnetmask("${local.provisioner_ip}/32")) ? "${local.provisioner_ip}/128" : null
}

data "http" "provisoner_ip" {
  url = "http://icanhazip.com"
}

resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "keypair" {
  key_name   = "example"
  public_key = tls_private_key.keypair.public_key_openssh
}

output "private_key" {
  value     = tls_private_key.keypair.private_key_pem
  sensitive = true
}

output "management_ip" {
  value = aws_instance.management.public_ip
}
