bind_addr = "0.0.0.0"

advertise {
  # We need to specify our host's IP because we can't
  # advertise 0.0.0.0 to other nodes in our cluster.
  rpc = "192.168.10.10:4647"
}

client {
  network_interface = "eth1"

  options {
    "docker.cleanup.image" = false
    "consul.address"       = "192.168.10.10:8500"
  }
}
