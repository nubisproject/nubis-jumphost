provider "aws" {
  region = "${var.aws_region}"
}

module "image" {
  source = "github.com/nubisproject/nubis-terraform///images?ref=develop"

  region        = "${var.aws_region}"
  image_version = "${var.nubis_version}"
  project       = "nubis-jumphost"
  os            = "centos"
}

resource "aws_eip" "jumphost" {
  lifecycle {
    create_before_destroy = true
  }

  count = "${var.enabled * length(var.arenas)}"
  vpc   = true
}

resource "aws_route53_record" "ui" {
  count   = "${var.enabled * length(var.arenas)}"
  zone_id = "${var.zone_id}"
  name    = "jumphost.${var.arenas[count.index]}"
  type    = "A"
  ttl     = "120"
  records = ["${element(aws_eip.jumphost.*.public_ip, count.index)}"]
}

resource "aws_security_group" "jumphost" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  name_prefix = "${var.project}-${var.arenas[count.index]}-"
  description = "Jumphost for SSH"

  vpc_id = "${element(split(",",var.vpc_ids), count.index)}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "0"
    to_port     = "8"
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Put back Amazon Default egress all rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name             = "${var.project}-${var.arenas[count.index]}"
    Region           = "${var.aws_region}"
    Arena            = "${var.arenas[count.index]}"
    TecnnicalContact = "${var.technical_contact}"
  }
}

resource "aws_iam_instance_profile" "jumphost" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }

  name = "${var.project}-${var.arenas[count.index]}-${var.aws_region}"
  role = "${element(aws_iam_role.jumphost.*.name, count.index)}"
}

resource "aws_iam_role" "jumphost" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  name = "${var.project}-${var.arenas[count.index]}-${var.aws_region}"
  path = "/nubis/${var.project}/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "jumphost" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  name = "${var.project}-${var.arenas[count.index]}-${var.aws_region}"
  role = "${element(aws_iam_role.jumphost.*.id, count.index)}"

  policy = <<EOF
{
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Action": [
                "ec2:AssociateAddress",
                "ec2:DisassociateAddress"
              ],
              "Resource": "*"
            }
          ]
        }
EOF
}

resource "aws_launch_configuration" "jumphost" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  name_prefix = "${var.project}-${var.arenas[count.index]}-${var.aws_region}-"

  image_id = "${module.image.image_id}"

  instance_type        = "t2.nano"
  key_name             = "${var.key_name}"
  iam_instance_profile = "${element(aws_iam_instance_profile.jumphost.*.name, count.index)}"
  enable_monitoring    = false

  associate_public_ip_address = true

  security_groups = [
    "${element(aws_security_group.jumphost.*.id, count.index)}",
    "${element(split(",",var.internet_access_security_groups), count.index)}",
    "${element(split(",",var.shared_services_security_groups), count.index)}",
    "${element(split(",",var.ssh_security_groups), count.index)}",
  ]

  user_data = <<EOF
NUBIS_PROJECT=${var.project}
NUBIS_ARENA=${var.arenas[count.index]}
NUBIS_ACCOUNT=${var.service_name}
NUBIS_DOMAIN=${var.nubis_domain}
NUBIS_JUMPHOST_EIP=${element(aws_eip.jumphost.*.id,count.index)}
NUBIS_SUDO_GROUPS="${var.nubis_sudo_groups}"
NUBIS_USER_GROUPS="${var.nubis_user_groups}"
EOF
}

resource "aws_autoscaling_group" "jumphost" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  #XXX: Fugly, assumes 3 subnets per arenas, bad assumption, but valid ATM
  vpc_zone_identifier = [
    "${element(split(",",var.public_subnet_ids), (count.index * 3) + 0 )}",
    "${element(split(",",var.public_subnet_ids), (count.index * 3) + 1 )}",
    "${element(split(",",var.public_subnet_ids), (count.index * 3) + 2 )}",
  ]

  name                      = "${var.project}-${var.arenas[count.index]} (LC ${element(aws_launch_configuration.jumphost.*.name, count.index)})"
  max_size                  = "2"
  min_size                  = "1"
  health_check_grace_period = 10
  health_check_type         = "EC2"
  desired_capacity          = "1"
  force_delete              = true
  launch_configuration      = "${element(aws_launch_configuration.jumphost.*.name, count.index)}"

  wait_for_capacity_timeout = "60m"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "Jumphost (${var.nubis_version}) for ${var.service_name} in ${var.arenas[count.index]}"
    propagate_at_launch = true
  }

  tag {
    key                 = "ServiceName"
    value               = "${var.project}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Arena"
    value               = "${var.arenas[count.index]}"
    propagate_at_launch = true
  }

  tag {
    key                 = "TechnicalContact"
    value               = "${var.technical_contact}"
    propagate_at_launch = true
  }
}
