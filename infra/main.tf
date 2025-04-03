terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "kittygram-terraform-state"
    region = "ru-central1"
    key    = "tf-state.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.89.0"
    }
  }
}

provider "yandex" {
  zone      = "ru-central1-a"
  cloud_id  = "b1gjhns5mdgfvvsk8qud"
  folder_id = "b1glgve5lotc5cunfnm5"
  service_account_key_file = "key.json"
}

resource "yandex_vpc_network" "kittygram-network" {
  name = "kittygram-network"
}

resource "yandex_vpc_subnet" "kittygram-subnet" {
  name           = "kittygram-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.kittygram-network.id
  v4_cidr_blocks = ["10.2.0.0/16"]
}

resource "yandex_vpc_security_group" "kittygram-sg" {
  name       = "kittygram-security-group"
  network_id = yandex_vpc_network.kittygram-network.id

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }
}

data "yandex_compute_image" "ubuntu" {
  family    = "ubuntu-2004-lts"
  folder_id = "standard-images"
}


resource "yandex_compute_instance" "vm" {
  name = "kittygram-terraform-vm"
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.Ubuntu.id
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.kittygram-subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kittygram-sg.id]
  }
  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}

variable "ssh_public_key" {
  description = "Public SSH key for VM access"
  type        = string
}

variable "yc_service_account_key" {
  description = "Service account key for Yandex Cloud (JSON content)"
  type        = string
  sensitive   = true
}