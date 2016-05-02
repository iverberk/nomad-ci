job "consul" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "system"
  priority    = 50

  update {
    stagger      = "10s"
    max_parallel = 1
  }

  group "consul" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "consul" {
      driver = "exec"

      config {
        command = "/usr/bin/consul/bin/consul"
        args    = ["agent", "-dev", "-config-dir=/usr/bin/consul/config", "-advertise=192.168.10.10", "-client=192.168.10.10"]
      }

      service {
        name = "consul"
        tags = ["global", "consul"]
        port = "http"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 300
        memory = 128

        network {
          mbits = 10

          port "dns" {
            static = 8600
          }

          port "http" {
            static = 8500
          }
        }
      }

      logs {
        max_files     = 10
        max_file_size = 15
      }

      kill_timeout = "20s"
    }
  }
}
