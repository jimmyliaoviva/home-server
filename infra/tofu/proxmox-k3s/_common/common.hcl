# Common Configuration
# Shared defaults used across all environments

locals {
  # Default system configuration
  default_system_config = {
    timezone = "Asia/Taipei"
    locale   = "en_US.UTF-8"
  }

  # Default network DNS servers
  default_dns = {
    primary   = "8.8.8.8"
    secondary = "1.1.1.1"
  }

  # Default network configuration
  default_network = {
    gateway        = "192.168.1.1"
    nameserver     = "8.8.8.8"
    nameserver_2   = "1.1.1.1"
    domain         = "local"
    interface_name = "eth0"
  }
}
