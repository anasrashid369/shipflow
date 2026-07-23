resource "aws_ecr_repository" "inventory_service" {
  name                 = "shipflow-inventory-service"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "shipflow-inventory-service"
  }
}