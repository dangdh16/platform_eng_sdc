locals {
  name   = "${basename(path.cwd)}"
  region =  var.region
  bucket = var.bucket
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  user_data_base64 = templatefile("${path.module}/userdata.tpl", { 
    database_address = aws_db_instance.default_db.address 
  })
  tags = {
    Name       = local.name
  }
}