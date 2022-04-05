data "google_client_openid_userinfo" "me" {}

resource "google_compute_address" "example" {
  count  = var.instance_example["count"]
  name   = format("%s-%03d", module.label.id, count.index + 1)
  region = var.region
}

resource "google_compute_disk" "example" {
  count = var.instance_example["count"]
  name  = format("%s-%03d", module.label.id, count.index + 1)
  type  = "pd-standard"
  zone  = element(var.zones, count.index % 2)
  image = var.instance_example["image"]
  size  = var.instance_example["size"]
}

resource "google_compute_instance" "example" {
  count        = var.instance_example["count"]
  name         = format("%s-%s-%03d", module.label.id, var.instance_example["name"], count.index + 1)
  machine_type = var.instance_example["machine_type"]
  zone         = element(var.zones, count.index % 2)
  tags         = var.instance_example_tags

  boot_disk {
    source = element(google_compute_disk.example.*.id, count.index)
  }

  network_interface {
    subnetwork = element(module.vpc.subnets_names, count.index % 2)

    access_config {
      # static external ip
      nat_ip = element(google_compute_address.example.*.address, count.index)
    }
  }

  metadata = {
    block-project-ssh-keys = "true"
    ssh-keys               = "${split("@", data.google_client_openid_userinfo.me.email)[0]}:${tls_private_key.ssh.public_key_openssh}"
  }
}

