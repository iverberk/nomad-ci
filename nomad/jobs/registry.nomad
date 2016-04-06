job "registry" {
	region = "global"
	datacenters = ["dc1"]
	type = "service"
	priority = 50

	update {
		stagger = "10s"
		max_parallel = 1
	}

	group "registry" {
		count = 1

		restart {
			attempts = 10
			interval = "5m"
			delay = "25s"
			mode = "delay"
		}

		task "registry" {
			driver = "docker"
			config {
				image = "registry:2"
				port_map {
					api = 5000
				}
			}

			service {
				name = "registry"
				tags = ["global", "registry"]
				port = "api"
				check {
					name = "alive"
					type = "tcp"
					interval = "10s"
					timeout = "2s"
				}
			}

			resources {
				cpu = 500 
				memory = 768 
				network {
					mbits = 10
					port "api" {
                      static = 5000
                    }
				}
			}

			logs {
			  max_files = 10
              max_file_size = 15
			}
			 
			kill_timeout = "20s"
		}
	}
}
