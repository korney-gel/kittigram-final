terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "kittygram-terraform-state"
    region = "ru-central1"
    key = "tf-state.tfstate"
    skip_region_validation = true
    skip_credentials_validation = true
    skip_requesting_account_id = true
    skip_s3_checksum = true
  }
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "~> 0.89.0"
    }
  }
}

provider "yandex" {
  zone = "ru-central1-a"
  cloud_id = "b1gjhns5mdgfvvsk8qud"
  folder_id = "b1glgve5lotc5cunfnm5"
  service_account_key_file = "./infra/key.json"
}

# Создаём виртуальную сеть - изолированный сетевой домен для наших ресурсов
# Сети в Yandex Cloud подобны VPC (Virtual Private Cloud) в других облачных провайдерах
resource "yandex_vpc_network" "kittygram-network" {
  name = "kittygram-network"                   # Человекочитаемое название ресурса
}

# Создаём подсеть в рамках нашей виртуальной сети
# Подсеть - это диапазон IP-адресов внутри сети, привязанный к конкретной зоне доступности
resource "yandex_vpc_subnet" "kittygram-subnet" {
  name           = "kittygram-subnet"          # Название подсети
  zone           = "ru-central1-a"         # Зона доступности должна совпадать с провайдером
  network_id     = yandex_vpc_network.kittygram-network.id  # Связь с родительской сетью
  v4_cidr_blocks = ["10.2.0.0/16"]         # Диапазон IP-адресов в нотации CIDR (65536 адресов)
}

# Создание ВМ
resource "yandex_compute_instance" "vm" {
  name = "kittygram-terraform-vm" # Имя ВМ

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd87va5cc00gaq2f5qfb" # Ubuntu 20.04 LTS
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.kittygram-subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}

variable "ssh_public_key" {
  description = "Public SSH key for VM access"
  type        = string
}


