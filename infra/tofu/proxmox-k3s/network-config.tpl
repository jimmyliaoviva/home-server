version: 2
ethernets:
  ${interface_name}:
    dhcp4: false
    addresses:
      - ${ip_address}/${netmask}
    gateway4: ${gateway}
    nameservers:
      addresses:
        - ${nameserver_1}
        - ${nameserver_2}