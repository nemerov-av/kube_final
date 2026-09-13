
variable "yc_cloud_id" {
  type = string
}

variable "yc_folder_id" {
  type = string
}

variable "service_account_id" {
  type = string
}

variable "ssh_key_path" {
  type = string
}






# Network

resource "yandex_vpc_network" "k8s-network" {
  name = "k8s-network"
}

resource "yandex_vpc_subnet" "k8s-subnet-1" {
  name           = "k8s-subnet-1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
  depends_on = [
    yandex_vpc_network.k8s-network,
  ]
}

resource "yandex_vpc_subnet" "k8s-subnet-2" {
  name           = "k8s-subnet-2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.k8s-network.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  depends_on = [
    yandex_vpc_network.k8s-network,
  ]
}

resource "yandex_vpc_subnet" "k8s-subnet-3" {
  name           = "k8s-subnet-3"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.k8s-network.id
  v4_cidr_blocks = ["192.168.30.0/24"]
  depends_on = [
    yandex_vpc_network.k8s-network,
  ]
}

# Compute instance group for control-plane

resource "yandex_compute_instance_group" "k8s-masters" {
  name               = "kube-masters"
  service_account_id = yandex_iam_service_account.for-autoscale.id #var.service_account_id
  depends_on = [
    yandex_vpc_network.k8s-network,
    yandex_vpc_subnet.k8s-subnet-1,
    yandex_vpc_subnet.k8s-subnet-2,
    yandex_vpc_subnet.k8s-subnet-3,
    yandex_resourcemanager_folder_iam_member.vm-autoscale-sa-role-compute,
  ]

  instance_template {

    name = "master-{instance.index}"

    platform_id = "standard-v3"
    
    
    
    resources {
      cores         = 2
      memory        = 2
      core_fraction = 20
    }
    boot_disk {
      initialize_params {
        image_id = "fd8clal01mnr2lnop5vr" # ubuntu-2404-lts-oslogin
        size     = 10
        type     = "network-ssd"
      }
    }

    network_interface {
      network_id = yandex_vpc_network.k8s-network.id
      subnet_ids = [
        yandex_vpc_subnet.k8s-subnet-1.id,
        yandex_vpc_subnet.k8s-subnet-2.id,
        yandex_vpc_subnet.k8s-subnet-3.id,
      ]
      nat = true
    }

    metadata = {
      ssh-keys = "ubuntu:${file("${var.ssh_key_path}")}"
    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = [
      "ru-central1-a",
      "ru-central1-b",
      "ru-central1-d",
    ]
  }

  deploy_policy {
    max_unavailable = 1
    max_creating    = 1
    max_expansion   = 1
    max_deleting    = 1
  }
}

# Compute instance group for workers

resource "yandex_compute_instance_group" "k8s-workers" {
  name               = "kube-workers"
  service_account_id = yandex_iam_service_account.for-autoscale.id  #var.service_account_id
  depends_on = [
    yandex_vpc_network.k8s-network,
    yandex_vpc_subnet.k8s-subnet-1,
    yandex_vpc_subnet.k8s-subnet-2,
    yandex_vpc_subnet.k8s-subnet-3,
    yandex_resourcemanager_folder_iam_member.vm-autoscale-sa-role-compute,
  ]

  instance_template {

    name = "worker-{instance.index}"

    platform_id = "standard-v3"
    
    

    resources {
      cores         = 2
      memory        = 8
      core_fraction = 20
    }

    boot_disk {
      initialize_params {
        image_id = "fd8clal01mnr2lnop5vr" # Ubuntu 24.04 LTS
        size     = 40
        type     = "network-hdd"
      }
    }

    network_interface {
      network_id = yandex_vpc_network.k8s-network.id
      subnet_ids = [
        yandex_vpc_subnet.k8s-subnet-1.id,
        yandex_vpc_subnet.k8s-subnet-2.id,
        yandex_vpc_subnet.k8s-subnet-3.id,
      ]
      nat = true
    }

    metadata = {
      ssh-keys = "ubuntu:${file("${var.ssh_key_path}")}"
    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    zones = [
      "ru-central1-a",
      "ru-central1-b",
      "ru-central1-d",
    ]
  }

  deploy_policy {
    max_unavailable = 1
    max_creating    = 1
    max_expansion   = 1
    max_deleting    = 1
  }
}

# Compute instance group for the LB

resource "yandex_compute_instance_group" "k8s-haproxy" {
  name               = "kube-haproxy"
  service_account_id = yandex_iam_service_account.for-autoscale.id #var.service_account_id
  depends_on = [
    yandex_vpc_network.k8s-network,
    yandex_vpc_subnet.k8s-subnet-1,
    yandex_vpc_subnet.k8s-subnet-2,
    yandex_vpc_subnet.k8s-subnet-3,
    yandex_resourcemanager_folder_iam_member.vm-autoscale-sa-role-compute,
  ]

  instance_template {

    name = "haproxy-{instance.index}"

    platform_id = "standard-v3"

    

    resources {
      cores         = 2
      memory        = 2
      core_fraction = 20
    }

    boot_disk {
      initialize_params {
        image_id = "fd8clal01mnr2lnop5vr" # Ubuntu 24.04 LTS
        size     = 10
        type     = "network-hdd"
      }
    }

    network_interface {
      network_id = yandex_vpc_network.k8s-network.id
      subnet_ids = [
        yandex_vpc_subnet.k8s-subnet-1.id,
        yandex_vpc_subnet.k8s-subnet-2.id,
        yandex_vpc_subnet.k8s-subnet-3.id,
      ]
      nat = true

    }

    metadata = {
      ssh-keys = "ubuntu:${file("${var.ssh_key_path}")}"
    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    zones = [
      "ru-central1-a",
      "ru-central1-b",
      "ru-central1-d",
    ]
  }

  deploy_policy {
    max_unavailable = 1
    max_creating    = 1
    max_expansion   = 1
    max_deleting    = 1
  }
}
