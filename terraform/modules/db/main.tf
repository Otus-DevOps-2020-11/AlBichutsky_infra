resource "yandex_compute_instance" "db" {

  # name = "reddit-db"
  for_each = var.names_db
  name     = "reddit-db-${each.key}"

  allow_stopping_for_update = true
  scheduling_policy {
    preemptible = true
  }

  labels = {
    tags = "reddit-db"
  }

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
