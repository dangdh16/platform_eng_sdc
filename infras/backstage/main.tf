# module "backstage" {
#   source = "../modules/terraform-aws-ec2-instance"

#   name = local.name

#   ami                         = data.aws_ami.ubuntu.id
#   instance_type               = var.instance_type
#   availability_zone           = tolist(data.aws_availability_zones.available.names)[0]
#   subnet_id                   = data.aws_subnet.subneta.id
#   vpc_security_group_ids      = [module.security_group.security_group_id]
#   associate_public_ip_address = true
#   disable_api_stop            = false

#   create_iam_instance_profile = true
#   iam_role_description        = "IAM role for EC2 instance"
#   iam_role_policies = {
#     AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
#   }
#   user_data            = local.user_data
# #   user_data_base64     = local.user_data_base64
#   user_data_replace_on_change = true

#   enable_volume_tags = false
#   root_block_device = [
#     {
#       encrypted   = true
#       volume_type = "gp3"
#       throughput  = 200
#       volume_size = 20
#       tags = {
#         Name = "${local.name}-ebs"
#       }
#     },
#   ]
#   tags = local.tags
# }

module "security_group" {
  source  = "../modules/terraform-aws-security-group"

  name        = local.name
  description = "Security group for example usage with EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

module "backstage-asg" {
  source = "../modules/terraform-aws-autoscaling"
    
  # Autoscaling group
  name            = "${local.name}-asg"
  use_name_prefix = false
  instance_name   = "${local.name}-instance"

  ignore_desired_capacity_changes = true

  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  default_instance_warmup   = 300
  health_check_type         = "EC2"
  vpc_zone_identifier       = [data.aws_subnet.subneta.id, data.aws_subnet.subnetb.id]
#   service_linked_role_arn   = aws_iam_service_linked_role.autoscaling.arn

  # Traffic source attachment
  create_traffic_source_attachment = true
  traffic_source_identifier        = module.backstage-alb.target_groups["ex_asg"].arn
  traffic_source_type              = "elbv2"

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay             = 600
      checkpoint_percentages       = [35, 70, 100]
      instance_warmup              = 300
      min_healthy_percentage       = 50
      auto_rollback                = true
      scale_in_protected_instances = "Refresh"
      standby_instances            = "Terminate"
    }
    triggers = ["tag"]
  }

  # Launch template
  launch_template_name        = "${local.name}-launch-template"
  launch_template_description = "Complete launch template example"
  update_default_version      = true

  image_id          = data.aws_ami.ubuntu.id
  instance_type     = var.instance_type
  user_data         = base64encode(local.user_data)
  ebs_optimized     = false
  enable_monitoring = false

  create_iam_instance_profile = true
  iam_role_name               = "${local.name}-iam-role"
  iam_role_path               = "/ec2/"
  iam_role_description        = "Complete IAM role example"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 20
        volume_type           = "gp2"
      }
    }
  ]

  capacity_reservation_specification = {
    capacity_reservation_preference = "open"
  }

  placement = {
    availability_zone = "${local.region}a"
  }

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = { WhatAmI = "Instance" }
    },
    {
      resource_type = "volume"
      tags          = merge({ WhatAmI = "Volume" })
    },
    {
      resource_type = "spot-instances-request"
      tags          = merge({ WhatAmI = "SpotInstanceRequest" })
    }
  ]

  tags = local.tags
  # Target scaling policy schedule based on average CPU load
  scaling_policies = {
    avg-cpu-policy-greater-than-50 = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 1200
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
      }
    }
  }
}

module "backstage-alb" {
  source  = "../modules/terraform-aws-alb"

  name = local.name

  vpc_id  = data.aws_vpc.default.id
  subnets = [data.aws_subnet.subneta.id, data.aws_subnet.subnetb.id]

  # For example only
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    ex_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ex_asg"
      }
    }
  }

  target_groups = {
    ex_asg = {
      backend_protocol                  = "HTTP"
      backend_port                      = 80
      target_type                       = "instance"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      # There's nothing to attach here in this definition.
      # The attachment happens in the ASG module above
      create_attachment = false
    }
  }

  tags = local.tags
}