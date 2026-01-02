# Proxmox VM resource definition
resource "proxmox_vm_qemu" "k3s_vm" {
  # Basic VM configuration
  name        = var.vm_config.name
  desc        = var.vm_config.description
  target_node = var.proxmox_config.node

  # Clone from template
  clone      = var.vm_config.template
  full_clone = true

  # VM specifications from variables
  cores   = var.vm_config.cores
  memory  = var.vm_config.memory
  sockets = 1

  # Boot and BIOS settings
  bios = "seabios"
  boot = "order=scsi0;net0"

  # QEMU guest agent
  agent = 1

  # Serial console for terminal access
  serial {
    id   = 0
    type = "socket"
  }

  scsihw = var.vm_config.scsihw

  # Main system disk
  disk {
    slot    = "scsi0"
    type    = "disk"
    storage = var.vm_config.storage
    size    = var.vm_config.disk_size
    format  = "raw"
    cache   = "writethrough"
    backup  = true
  }

  # Cloud-Init drive (required for cloud-init to work)
  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = var.vm_config.storage
  }

  # Network interface configuration
  network {
    id     = 0
    model  = "virtio"
    bridge = var.vm_config.network
  }

  # IP configuration - static or DHCP
  ipconfig0 = var.network_config.ip_address != "dhcp" ? "ip=${var.network_config.ip_address},gw=${var.network_config.gateway}" : "ip=dhcp"

  # DNS configuration
  nameserver = "${var.network_config.nameserver} ${var.network_config.nameserver_2}"

  # SSH keys for cloud-init
  sshkeys = var.ssh_config.public_key

  # Cloud-init user configuration
  ciuser = var.ssh_config.username

  # VM lifecycle management
  lifecycle {
    ignore_changes = [
      # Ignore changes to network configuration after initial creation
      network,
      # Ignore changes to cloud-init after initial setup
      cicustom,
      sshkeys,
    ]
  }
}
