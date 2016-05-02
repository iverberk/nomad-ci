Scalable CI/CD with Jenkins and Nomad 
=====================================

This is the accompanying repository to my [blog post](http://www.ivoverberk.nl/scalable-ci-cd-with-nomad-and-jenkins/) 
on Scalable CI/CD with Jenkins and Nomad.

Run ```vagrant up``` to start the platform (you will need about 4GB of free
memory). The Vagrant shell provisioner is running a script that you can find in
the Vagrantfile. It is starting Nomad as a daemon and scheduling Consul to run
as a system service. It is also running dnsmasq and reconfiguring the Docker
daemon to listen on a tcp address. Take a look at the files in the config
directory to see how this is done.

**important**: if you restart the Vagrant box you will need to run the provision
step again to make sure that Nomad and Consul are up and running:

```
vagrant provision
```

The Vagrantbox is configured to use 192.168.10.10 as a private IP on a host-only
network. At this point Consul should be available on
[http://192.168.10.10:8500/ui](http://192.168.10.10:8500/ui).  You can ssh into
the Vagrant environment to verify that Nomad has actually scheduled Consul as a
[system job](https://www.nomadproject.io/docs/jobspec/schedulers.html):

``` 
vagrant ssh 
nomad status consul 
```

All the Nomad [job
specifications](https://www.nomadproject.io/docs/jobspec/index.html) can be
found in the [jobs](https://github.com/iverberk/nomad-ci/tree/master/nomad/jobs)
directory.

###Platform Services

At this point we are ready to start additional CI/CD services. In the
[scripts](https://github.com/iverberk/nomad-ci/tree/master/scripts) directory
there are numerous helper scripts to start and stop services with Nomad. They
are there for your convenience but you should take a look at the commands inside
and even run them manually within the Vagrant box to really understand what is
happening.

Exit the virtual machine and run the following services from the root of the
repository.

#####Docker registry

``` scripts/start-registry.sh ```. This instructs Nomad to schedule a Docker 
registry container. It takes some time to download the image but after a while 
the registry should be up and running and visible as a service in Consul. 

**important**: the registry is not using a volume so if you restart the Vagrant
box and Nomad schedules a new registry it will have lost all the previous images.
You can just rebuild and push the images if necessary.

#####Jenkins Master

The Jenkins master will be a custom built container that has all the necessary
configuration to start building our application. 

Take a look at the [jenkins-master](https://github.com/iverberk/nomad-ci/tree/master/docker/jenkins-master) 
directory. You'll find a configuration file for the Jenkins master, a list of 
plugins to install and a template Jenkins home directory that contains all our 
build job configurations. This could easily be replaced by something like the 
Job DSL configuration if that's what you prefer.

*It also contains a custom Jenkins [Nomad plugin](https://github.com/iverberk/jenkins-nomad) 
that I wrote to make Nomad available as a Cloud target. This allows Jenkins to 
dynamically bring up new build slaves with Nomad, based on workload.*

To build the Jenkins master image and push it over to our private registry run:
``` docker/jenkins-master/build.sh ``` 

**After** building the image we schedule it with Nomad: ``` scripts/start-jenkins-master.sh ``` 
After a short while the Jenkins master should be reachable on [http://192.168.10.10:8080](http://192.168.10.10:8080). 
You can inspect the Nomad cloud configuration on [http://192.168.10.10:8080/configure](http://192.168.10.10:8080/configure)
at the bottom of the page.

#####Selenium Hub

Finally we'll schedule a Selenium Hub on our platform as a central coordination
point for our browser test grid: ```scripts/start-selenium-hub.sh``` After a
while it should be available on [http://192.168.10.10:4444/grid/console](http://192.168.10.10:4444/grid/console)

We now have a fully functioning CI/CD platform. You can check Consul to verify
that all services are running. 

###Application 

I've created a simple microservices application, called 'micro-app' to illustrate 
the possibilities of our new platform. You can find it in the [micro-app](https://github.com/iverberk/nomad-ci/tree/master/micro-app) directory. 

#####Architecture

The main purpose of the application is to simply generate, and possibly store, a
personal introduction sentence of the following form: 

>Hello, my name is {name} and I'm {age} years old and I live in the $env
>environment! 

The {name} and {age} part of this sentence are actually generated dynamically by
different
[services](https://github.com/iverberk/nomad-ci/tree/master/micro-app/services) 
that are built and run separately from the main application. They are available 
to the micro-app application over the network via a HTTP request. The $env part 
is determined by the environment that the application is deployed to.

It uses a Redis cache to potentially store an introduction sentence. This can be
triggered by adding ```?store=true``` as a GET parameter. The next generated
introduction will be stored and reused on subsequent refreshes. Use
```?clear=true``` to clear the cache and start generating new introductions.

#####Building

To build the micro-app microservices we need to provide Jenkins with the right
build environment. Since we'll be running all our builds in a container this
means that we need to create an image with all dependencies necessary to build
and test the application. For the micro-app you can find the configuration in
[this](https://github.com/iverberk/nomad-ci/blob/master/micro-app/support/jenkins-slave/Dockerfile) 
Dockerfile.

At the moment there are only two basic requirements in order for Jenkins/Nomad
to use this as a build slave: Java must be available to run the Jenkins slave
process and there can be no [entrypoint](https://docs.docker.com/engine/reference/run/#entrypoint-default-command-to-execute-at-runtime) 
since Nomad injects the Jenkins slave command during scheduling (this won't be 
necessary anymore if/when Nomad allows overriding of the entrypoint). 

For the micro-app, a Go environment, NodeJS and some NPM modules are needed to
build and run integration tests. Build and push the Jenkins slave image with: 

``` micro-app/support/jenkins-slave/build.sh ```

With our slave image available to Nomad and Jenkins, we can now start building 
and unit-testing our services. Run a new build on the [Platform - Build](http://192.168.10.10:8080/) 
project. This will trigger the build of three other projects that are responsible for 
compiling, testing and packaging of the services.

The Jenkins jobs are really simple, they just trigger build scripts in the repository.
Please take a moment to look at the different job configurations and see how
they are restricted to run only on a Nomad cloud. 

Once you trigger the build for the "Platform - Build" project you'll find that 
Jenkins is waiting for available executors. At the moment it has no build 
environments that match the restriction labels that are set in the job configurations. 

It is at this point that Jenkins will ask Nomad to start scheduling additional
build slaves as defined in the Nomad cloud configuration. After a while you
should see slaves becoming available to Jenkins and the builds should start.
Depending on how Jenkins chooses to schedule there might be multiple slaves
starting. The builds are run in a container that is based on the image we
previously created.

#####Deploying 

Now that we have successfully built and packaged our services as Docker 
containers it is time to deploy them to a live environment. 

Run a new build on the [Platform - Deploy](http://192.168.10.10:8080/) project. 
You will be asked to providea name for the target environment. You can use anything 
you want here. The full working application, including the services and Redis, 
will be deployed to this environment. For now we'll use "test" as the target environment.  

During deployment you can check Consul on [http://192.168.10.10:8500/ui](http://192.168.10.10:8500/ui) to
see that the containers are being spun up. After some time the url to the environment 
will available in the build output. Paste the url into a browser and see the 
application in a working state. If you deploy again to a different environment 
it will spin up a totally separate set of services (be aware that the VM only 
has 4gb ram available). 

Nomad is again responsible for scheduling the application services to the
cluster. To see how this is performed you can check the
[deploy script](https://github.com/iverberk/nomad-ci/blob/master/micro-app/deploy/deploy.sh). 
The script basically submits job definitions to Nomad after it has replaced some 
placeholders to set the correct environment. Take some time to study the 
[job templates](https://github.com/iverberk/nomad-ci/tree/master/micro-app/deploy/jobs) 
and how the deploy script ties it all together.

If you are done testing bring down the test environment with the [Platform -
Stop](http://192.168.10.10:8080/) project. This is necessary to free up resources for the next section.

#####Testing 

Let's also test our application with Selenium to round it all off and again 
show how useful Nomad is in scheduling these kinds of workloads. 

At the beginning of this tutorial we started a Selenium Hub service. During the
integration test, two browser nodes (Chrome and Firefox) will be scheduled to
connect to the hub automatically. After that, an integration environment will be
brought up in exactly the same way as described above. Once the integration
environment is available, a Selenium test will be started to test that the
application output is correct. The test will drive both browsers in parallel.

**important**: the integration test will spin up a dedicated environment for the
integration test, so make sure that you stop any previously running environments
(or you will run out of resources).

Start the test by running the [Platform - Integration Test](http://192.168.10.10:8080/) project. You can
follow the test progress in the console output. You can also check Consul to see
that the browsers and services are being spun up (It might take some time to
download the browser images so if the test fails you can try again and it will
probably succeed).

Test results will be available in Jenkins after the tests have successfully
completed. You can check the mechanics of how this all works in [this](https://github.com/iverberk/nomad-ci/blob/master/micro-app/integration-tests/run_tests.sh) 
script. It basically asks Nomad to schedule the browser nodes and start a full 
set of application services. After the tests are done it clears the environment 
again, freeing up the resources.
