module "security_group" {
  source  = "../modules/terraform-aws-security-group"

  name        = "${local.name}-sg"
  description = "Security group for example usage with EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = 6
      description = "Backstage port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = 6
      description = "DB backstage port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 7007
      to_port     = 7007
      protocol    = 6
      description = "Backstage backend port"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = local.tags
}

module "db_security_group" {
  source  = "../modules/terraform-aws-security-group"

  name        = "${local.name}-dbsg"
  description = "Security group for Db"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = 6
      description = "DB backstage port"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

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
  security_groups          = [module.security_group.security_group_id]
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
  user_data         = base64encode(templatefile("${path.module}/userdata.tpl", { 
    database_address = aws_db_instance.default_db.address 
  }))
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
        volume_size           = 30
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
  depends_on = [ 
    aws_db_instance.default_db 
  ]
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
      protocol                  = "HTTP"
      port                      = 3000
      target_type                       = "instance"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true
      create_attachment = false
    }
  }

  tags = local.tags
}

resource "aws_db_instance" "default_db" {
  identifier              = "backstage-db"
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "13.8"
  parameter_group_name    = "default.postgres13"
  instance_class          = "db.t3.micro"
  username = "backstage"
  password = "backstage123"
  multi_az                = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 15
  availability_zone       = "us-east-1a"
  vpc_security_group_ids  = [module.db_security_group.security_group_id]
}