$script = <<SCRIPT

# Install Java and dnsmasq
apt-get install -y unzip daemon dnsmasq openjdk-7-jre-headless

# Symlink the Nomad binary for easy access
ln -s /vagrant/nomad/bin/nomad /usr/bin/nomad

# Start Nomad as a daemon in developer mode. This runs Nomad in server and client mode at the same time.
daemon --name=nomad --output=/vagrant/nomad.log --command="/vagrant/nomad/bin/nomad agent -dev -config /vagrant/nomad/config"

echo Fetching Consul...
cd /tmp/
wget --quiet https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_linux_amd64.zip -O consul.zip
echo Installing Consul...
unzip consul.zip
sudo chmod +x consul
sudo mv consul /vagrant/consul/bin/consul

# Make sure the Consul binary and config are in the exec driver's chroot
cp -fr /vagrant/consul /usr/bin

# Give Nomad some time to start
sleep 5

# Schedule Consul on the node
/vagrant/nomad/bin/nomad run /vagrant/nomad/jobs/consul.nomad

# Copy service configuration files
sudo cp /vagrant/config/docker_daemon_config /etc/default/docker
sudo cp /vagrant/config/dnsmasq.conf /etc/dnsmasq.conf
sudo cp /vagrant/config/resolv.conf.dnsmasq /etc/resolv.conf.dnsmasq

# Restart services to activate new configuration
sudo service docker restart
sudo service dnsmasq restart

SCRIPT

Vagrant.configure(2) do |config|
 
  config.vm.define "ci" do |ci|
    ci.vm.box = "ubuntu/trusty64"
    ci.vm.network "private_network", ip: "192.168.10.10"
    ci.vm.provider "virtualbox" do |vb|
      vb.memory = 4096
      vb.cpus = 2
    end
    ci.vm.synced_folder ".", "/vagrant"
    ci.vm.provision "docker"
    ci.vm.provision "shell", inline: $script
  end

end
