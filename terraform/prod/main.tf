provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

# Создаем VPC-ресурсы для ВМ: сеть "app-network" и подсеть "app-subnet"

# resource "yandex_vpc_network" "app-network" {
# name = "app-network"
# }

# resource "yandex_vpc_subnet" "app-subnet" {
#  name           = "app-subnet"
#  zone           = "ru-central1-a"
#  network_id     = "${yandex_vpc_network.app-network.id}"
#  v4_cidr_blocks = ["192.168.10.0/24"]
# }

module "app" {
  source          = "../modules/app"
  public_key_path = var.public_key_path
  app_disk_image  = var.app_disk_image
  # сейчас подсеть уже создана в YC и определена в terraform.tfvars
  subnet_id = var.subnet_id
  # если ВМ создается в подсети "app-subnet" после запуска terraform, то
  # - закомментируем параметр выше
  # - закомментируем параметр subnet_id в terraform.tfvars 
  # - расскоментируем ниже
  # subnet_id       = yandex_vpc_subnet.app-subnet.id
}

module "db" {
  source          = "../modules/db"
  public_key_path = var.public_key_path
  db_disk_image   = var.db_disk_image
  # сейчас подсеть уже создана в YC и определена в terraform.tfvars
  subnet_id = var.subnet_id
  # если ВМ создается в подсети "app-subnet" после запуска terraform, то
  # - закомментируем параметр выше
  # - закомментируем параметр subnet_id в terraform.tfvars 
  # - расскоментируем ниже
  # subnet_id       = yandex_vpc_subnet.app-subnet.id
}
