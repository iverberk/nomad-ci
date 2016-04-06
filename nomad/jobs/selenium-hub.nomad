job "selenium-hub" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"
  priority    = 50

  update {
    stagger      = "10s"
    max_parallel = 1
  }

  group "selenium-hub" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "selenium-hub" {
      driver = "docker"

      config {
        image = "selenium/hub"

        port_map {
          hub = 4444
        }
      }

      env {
        GRID_UNREGISTER_IF_STILL_DOWN_AFTER = 4000
        GRID_NODE_POLLING                   = 2000
        GRID_CLEAN_UP_CYCLE                 = 2000
        GRID_TIMEOUT                        = 10000
      }

      service {
        name = "selenium-hub"
        tags = ["global", "selnium", "hub"]
        port = "hub"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 300
        memory = 384

        network {
          mbits = 10

          port "hub" {
            static = 4444
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
