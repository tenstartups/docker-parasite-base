# Docker Parasite Base Docker Image

This project is a very opinionated set of procedures and scripts for running applications on servers using Docker, with the fundamental aim of meeting the requirements of a twelve-factor application (http://12factor.net) and being able to bootstrap a server from scratch using a single Docker image that deploys files and runs additional services to run the application (kind of like a parasite).

The opinionated part is born of having spent the past year configuring and maintaining several applications using Docker, working through the various kinks, and watching the technologies evolve and improve.

This Docker image is not meant to be used on its own, but instead should be used as the base image for your application's `parasite` project, which should follow a very specific directory structure, similar to that of this base image.

### Parasite directory structure

    .
    ├── files            # Container configurations files organized by container named subdirectories.
    │   ├── host         # Host configuration files.
    │   │   ├── env      # Core initialization scripts that are used to bootstrap a new machine (base image only).
    │   │   ├── init     # Core initialization scripts that are used to bootstrap a new machine (base image only).
    │   │   ├── script   # System utility scripts used in the host to perform various operations.
    │   │   ├── startup  # Startup scripts that are run during the second stage initialization before system services are started.
    │   │   └── systemd  # Systemd unit descriptors for running all the services of your application.
    │   ├── service-1    # Configuration files service-1 organized by the service's requirements.
    │   │   └── ...
    │   ├── service-2    # Configuration files service-2 organized by the service's requirements.
    │   │   └── ...
    │   └── ...
    ├── lib              # Ruby source files
    ├── 10-base.yml      # YAML instructions on how to deploy files for this docker image (use numeric naming convention to ensure proper ordering during execution).
    ├── Dockerfile
    └── README.md

In order to create your own application-specific parasite image you should follow the specified directory structure and then publish the image to a private docker registry that your server machines can contact on boot.  You will need to initialize your server with a systemd service unit to start the parasite initialization process (see example
below).  The service unit can be manually deployed and enabled or automated through cloud-config.

```
# Example parasite stage one initialization systemd unit (/etc/systemd/system/parasite-init-stage-zero.service)

[Unit]
Description=Docker parasite stage one initialization
Requires=network-online.target docker.service

[Service]
RemainAfterExit=true
Restart=on-failure
ExecStartPre=/bin/sh -c "[ -f '/root/.docker/config.json' ] || \
  docker login --username <docker_username> --password <docker_password> <docker_registry_hostname>"
ExecStartPre=/usr/bin/docker pull <docker_parasite_image> \
ExecStartPre=/usr/bin/docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /parasite-config:/parasite-config \
  -e PARASITE_CONFIG_DIRECTORY=/parasite-config \
  -e PARASITE_DATA_DIRECTORY=/parasite-data \
  -e PARASITE_ROLE=web \
  -e PARASITE_STAGE=production \
  --net host \
  --privileged \
  <docker_parasite_image> \
  host
  ExecStart=/parasite-config/init/stage-one
```

The initialization process copies files from the image to a specified target location, which can be set with the PARASITE_CONFIG_DIRECTORY environment variable (default is /parasite-config).

You will need to create a configuration file in the `files` directory that describes how to copy files from the image to the target.  The configuration files in `files` are processed in alphabetical order, starting with `10-base.yml`, then yours (suggest calling it `20-something` aftewards.  Your Dockerfile should copy the contents of `host` and `container` to a directory that is the same name as the coniguration file, such as `20-something`.  Note that you can create multiple configuration files in the `files` directory as long as they all start with the same prefix (`20-something-something` for example).  Every file copies is processed through ERB, therefore any required environment should be set in the /parasite-config.env file.
