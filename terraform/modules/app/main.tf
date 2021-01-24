resource "yandex_compute_instance" "app" {

  # name = "reddit-app"
  count                     = var.count_app
  name                      = "reddit-app-${count.index}"
  allow_stopping_for_update = true
  scheduling_policy {
    preemptible = true
  }

  labels = {
    tags = "reddit-app"
  }
  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image
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
