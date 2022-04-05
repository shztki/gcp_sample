resource "google_compute_firewall" "allow_example_icmp" {
  name    = format("%s-%s", "icmp", module.label.id)
  network = module.vpc.network_name

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.office_cidr]
  target_tags   = [var.instance_example_tags[0]]
}

resource "google_compute_firewall" "allow_example_ssh" {
  name    = format("%s-%s", "ssh", module.label.id)
  network = module.vpc.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.office_cidr]
  target_tags   = [var.instance_example_tags[0]]
}

resource "google_compute_firewall" "allow_between_example" {
  name    = format("%s-%s", "allow-between", module.label.id)
  network = module.vpc.network_name

  allow {
    protocol = "all"
  }

  direction   = "INGRESS"
  source_tags = [var.instance_example_tags[0]]
  target_tags = [var.instance_example_tags[0]]
}

resource "google_compute_firewall" "deny_example_all" {
  name    = format("%s-%s", "deny-all", module.label.id)
  network = module.vpc.network_name

  deny {
    protocol = "all"
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  priority      = 1001
}
