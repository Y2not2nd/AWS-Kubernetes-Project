resource "aws_db_subnet_group" "yasn_rds_subnet_group" {
  name       = "yasn-rds-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "yasn_rds" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = var.db_engine_version
  instance_class       = "db.t3.micro"
  db_name              = var.db_name
  username             = var.db_user
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.yasn_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.yasn_rds_sg.id]
  skip_final_snapshot  = true
}

resource "aws_security_group" "yasn_rds_sg" {
  name        = "yasn-rds-sg"
  description = "RDS security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "db_endpoint" {
  value = aws_db_instance.yasn_rds.address
}
