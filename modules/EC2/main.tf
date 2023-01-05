resource "aws_instance" "terraform-demo-1" {
  ami           = var.ami-1
  instance_type = var.instance_type-1
  key_name      = "ray-demo"

  user_data = file("user-data-script.sh")

  tags = {
    Name             = "terraform-demo-1"
    turbo_owner      = "Ray.Mileo@ibm.com"
    Terraform_Config = "https://github.com/turbonomic-integrations/terraform-demo/blob/main/terraform.tfvars::instance_type-1"
  }
}

resource "aws_instance" "terraform-demo-2" {
  ami           = var.ami-2
  instance_type = var.instance_type-2
  key_name      = "ray-demo"

  user_data = file("user-data-script.sh")

  tags = {
    Name             = "terraform-demo-2"
    turbo_owner      = "Ray.Mileo@ibm.com"
    Terraform_Config = "https://github.com/turbonomic-integrations/terraform-demo/blob/main/terraform.tfvars::instance_type-2"
  }
}

resource "aws_instance" "jfabry-waste-test" {
  ami           = var.ami-2
  instance_type = var.instance_type-4
  key_name      = "ray-demo"

  user_data = file("user-data-script.sh")

  tags = {
    Name             = "jfabry-waste-test"
    turbo_owner      = "tester@test.com"
    Terraform_Config = "https://github.com/turbonomic-integrations/terraform-demo/blob/main/terraform.tfvars::instance_type-3"
  }
}

resource "azurerm_virtual_machine" "vm_linux" {
  count = !contains(tolist([
    var.vm_os_simple, var.vm_os_offer
  ]), "WindowsServer") && !var.is_windows_image ? var.nb_instances : 0

  location                         = local.location
  name                             = "${var.vm_hostname}-vmLinux-${count.index}"
  network_interface_ids            = [element(azurerm_network_interface.vm[*].id, count.index)]
  resource_group_name              = var.resource_group_name
  vm_size                          = var.azure_vm_size
  availability_set_id              = var.zone == null ? azurerm_availability_set.vm[0].id : null
  delete_data_disks_on_termination = var.delete_data_disks_on_termination
  delete_os_disk_on_termination    = var.delete_os_disk_on_termination
  tags = {
    Name        = "jfabry-actions-test"
    turbo_owner = "tester@test.com"
  }
  zones = var.zone == null ? null : [var.zone]

  storage_os_disk {
    create_option     = "FromImage"
    name              = "osdisk-${var.vm_hostname}-${count.index}"
    caching           = "ReadWrite"
    disk_size_gb      = var.storage_os_disk_size_gb
    managed_disk_type = var.storage_account_type
  }
  boot_diagnostics {
    enabled     = var.boot_diagnostics
    storage_uri = var.boot_diagnostics ? try(var.external_boot_diagnostics_storage.uri, join(",", azurerm_storage_account.vm_sa[*].primary_blob_endpoint)) : ""
  }
  dynamic "identity" {
    for_each = length(var.identity_ids) == 0 && var.identity_type == "SystemAssigned" ? [var.identity_type] : []

    content {
      type = var.identity_type
    }
  }
  dynamic "identity" {
    for_each = length(var.identity_ids) > 0 || var.identity_type == "UserAssigned" ? [var.identity_type] : []

    content {
      type         = var.identity_type
      identity_ids = length(var.identity_ids) > 0 ? var.identity_ids : []
    }
  }
  os_profile {
    admin_username = var.admin_username
    computer_name  = "${var.vm_hostname}-${count.index}"
    admin_password = var.admin_password
    custom_data    = var.custom_data
  }
  os_profile_linux_config {
    disable_password_authentication = var.enable_ssh_key

    dynamic "ssh_keys" {
      for_each = var.enable_ssh_key ? local.ssh_keys : []

      content {
        key_data = file(ssh_keys.value)
        path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      }
    }
    dynamic "ssh_keys" {
      for_each = var.enable_ssh_key ? var.ssh_key_values : []

      content {
        key_data = ssh_keys.value
        path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      }
    }
  }
  dynamic "os_profile_secrets" {
    for_each = var.os_profile_secrets

    content {
      source_vault_id = os_profile_secrets.value["source_vault_id"]

      vault_certificates {
        certificate_url = os_profile_secrets.value["certificate_url"]
      }
    }
  }
  dynamic "plan" {
    for_each = var.is_marketplace_image ? ["plan"] : []

    content {
      name      = var.vm_os_offer
      product   = var.vm_os_sku
      publisher = var.vm_os_publisher
    }
  }
  dynamic "storage_data_disk" {
    for_each = range(var.nb_data_disk)

    content {
      create_option     = "Empty"
      lun               = storage_data_disk.value
      name              = "${var.vm_hostname}-datadisk-${count.index}-${storage_data_disk.value}"
      disk_size_gb      = var.data_disk_size_gb
      managed_disk_type = var.data_sa_type
    }
  }
  dynamic "storage_data_disk" {
    for_each = var.extra_disks

    content {
      create_option     = "Empty"
      lun               = storage_data_disk.key + var.nb_data_disk
      name              = "${var.vm_hostname}-extradisk-${count.index}-${storage_data_disk.value.name}"
      disk_size_gb      = storage_data_disk.value.size
      managed_disk_type = var.data_sa_type
    }
  }
  storage_image_reference {
    id        = var.vm_os_id
    offer     = var.vm_os_id == "" ? coalesce(var.vm_os_offer, module.os.calculated_value_os_offer) : ""
    publisher = var.vm_os_id == "" ? coalesce(var.vm_os_publisher, module.os.calculated_value_os_publisher) : ""
    sku       = var.vm_os_id == "" ? coalesce(var.vm_os_sku, module.os.calculated_value_os_sku) : ""
    version   = var.vm_os_id == "" ? var.vm_os_version : ""
  }

  lifecycle {
    precondition {
      condition     = !var.is_marketplace_image || (var.vm_os_offer != null && var.vm_os_publisher != null && var.vm_os_sku != null)
      error_message = "`var.vm_os_offer`, `vm_os_publisher` and `var.vm_os_sku` are required when `var.is_marketplace_image` is `true`."
    }
  }
}

resource "google_compute_instance" "default" {
  name         = "RayTest-VM01"
  machine_type = var.gcp_vm_size
  zone         = "us-west1-a"
  tags = {
    Name        = "RayTest-VM01"
    turbo_owner = "tester@test.com"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.id
  }
}
