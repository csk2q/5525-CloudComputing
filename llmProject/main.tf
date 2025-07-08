provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable Logging API
resource "google_project_service" "logging" {
  project = var.project_id
  service = "logging.googleapis.com"
  disable_on_destroy = false
}

# Custom service account
resource "google_service_account" "llm_vm_sa" {
  account_id   = "llm-vm-sa"
  display_name = "Service Account for LLM VM"
}

# Grant roles to custom service account

locals {
  ops_agent_roles = [
    "roles/artifactregistry.reader",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer",
  ]
}

resource "google_project_iam_member" "ops_agent_roles" {
  for_each = toset(local.ops_agent_roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.llm_vm_sa.email}"
}


# VPC Network

resource "google_compute_network" "llm_vpc_net" {
  name                    = "llm-vpc"
  auto_create_subnetworks = false
}

# VPC Subnetwork

resource "google_compute_subnetwork" "llm_subnet" {
  name          = "llm-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.llm_vpc_net.id
}

# VPC Firewall rules

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.llm_vpc_net.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
}

resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.llm_vpc_net.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.llm_vpc_net.name

  allow {
    protocol = "all"
  }

  source_ranges = ["10.0.0.0/16"]
}

# Startup script

data "template_file" "startup_script" {
  template = file("${path.module}/startup.sh")

  vars = {
    webhook_url = var.discord_webhook
    ar_image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo_name}/${var.image_name}"
  }
}

# Compute metadata

resource "google_compute_project_metadata_item" "ssh_keys" {
  key   = "ssh-keys"
  value = "${var.ssh_username}:${file(var.ssh_public_key_path)}"
}

# Compute instance
resource "google_compute_instance" "llm_vm" {
  name                      = "llm-vm"
  # machine_type              = "e2-micro"
  # A larger machine is needed for running the LLM
  machine_type              = "e2-medium"
  zone                      = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.llm_vpc_net.id
    subnetwork = google_compute_subnetwork.llm_subnet.id
    access_config {} # Enables external IP
  }

  service_account {
    email  = google_service_account.llm_vm_sa.email
    scopes = ["cloud-platform"]
  }

  # metadata = {
  #   ssh-keys = "${var.ssh_username}:${file(var.ssh_public_key_path)}"
  #   # enable-oslogin : "TRUE"
  # }

  # To see the output of this script run the following:
  # sudo journalctl -u google-startup-scripts.service
  metadata_startup_script = data.template_file.startup_script.rendered

  tags = ["http-server", "https-server"]
}

