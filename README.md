CoreOS Application Configuration Base Image
==

This project is a very opinionated set of procedures and scripts for running applications in CoreOS using Docker, with the fundamental aim of meeting the requirements of a twelve-factor application (http://12factor.net) and being able to bootstrap a CoreOS machine from scratch using a single Docker Image that deploys files and runs additional services to run the application (kind of like a parasite).

The opinionated part is born of having spent the past year configuring and maintaining several applications on CoreOS/Docker, working through the various kinks, and watching the technologies evolve and improve.

This Docker image is not meant to be used on its own, but instead should be used as the base image for your application's `coreos-parasite` project, which should follow a very specific directory structure, similar to that of this base image.

### Parasite directory structure

    .
    ├── conf.d         # YAML instructions on how to deploy files in the host and container directories.
    ├── container      # Container (Docker) configurations files.
    │   ├── conf       # Configuration files for each specific container service.
    │   ├── env        # Environment files (*.env) used inside of container services
    │   └── script     # Bash scripts used inside of container services.
    ├── host           # Host (CoreOS) configuration files.
    │   ├── env.d      # Individual environment files (*.env) that are merged into single files for systemd, docker and bash profile.
    │   ├── init       # Core initialization scripts that are used to bootstrap a new machine (base image only).
    │   ├── init.d     # Additional initialization bash scripts (*.sh) or CoreOS cloud config (*.yml) run during stage two initialization.
    │   ├── script     # Bash scripts used in the host to perform various operations.
    │   ├── systemd    # Systemd unit descriptors for running all the services of your application.
    │   └── tools.d    # Individual tools installation scripts called by the tools-install systemd service on startup.
    ├── Dockerfile     # Source files (alternatively `lib` or `app`)
    └── README.md

In order to create your own application-specific parasite image you should follow the specified directory structure and then publish the image to a private docker registry that your server machines can contact on boot.  You will need to launch your CoreOS instances with a cloud-config that looks something like this.

```yaml
#cloud-config
hostname: <%= hostname %>

write_files:
  - path: /parasite-config.env
    permissions: '0644'
    content: |
      DOCKER_USERNAME=<%= docker_username %>
      DOCKER_EMAIL=<%= docker_email %>
      DOCKER_PASSWORD=<%= docker_password %>
      STAGE=<%= stage %>
      ROLE=<%= role %>
      DOCKER_IMAGE_PARASITE_CONFIG=<%= docker_image %>
      CONFIG_DIRECTORY=<%= config_directory %>
      DATA_DIRECTORY=<%= data_directory %>

coreos:
  units:
    - name: parasite-init-stage-one.service
      command: start
      runtime: yes
      content: |
        [Unit]
        Description=CoreOS parasite stage one initialization
        Requires=network-online.target docker.service

        [Service]
        User=root
        Type=oneshot
        RemainAfterExit=true
        EnvironmentFile=/parasite-config.env
        EnvironmentFile=-/parasite-config-ext.env
        ExecStartPre=/usr/bin/bash -c "[ -f '/root/.docker/config.json' ] || docker login -u ${DOCKER_USERNAME} -e ${DOCKER_EMAIL} -p ${DOCKER_PASSWORD}"
        ExecStartPre=/usr/bin/docker run --rm \
          -v /var/run/${CONFIG_DIRECTORY}:${CONFIG_DIRECTORY} \
          --env-file=/etc/environment \
          --env-file=/parasite-config.env \
          --net host \
          ${DOCKER_IMAGE_PARASITE_CONFIG} \
          host
        ExecStart=/usr/bin/sh -c "/var/run/${CONFIG_DIRECTORY}/init/stage-one"
```

The key requirements are to set the server hostname (FQDN), create a /parasite-config.env file containing any required ERB environment variables, and create a systemd unit that logs into your Docker registry, runs your parasite image in host mode, then launches the parasite stage one initialization script.

This example demonstrates using erb in order to template the configuration for use with a fleet of machines, where each has its own hostname, stage and role.  The initialization process copies files from the image to a specified target location, which can be set with the CONFIG_DIRECTORY environment variable (default is /parasite-config).

You will need to create a configuration file in the `conf.d` directory that describes how to copy files from the image to the target.  The configuration files in `conf.d` are processed in alphabetical order, starting with `10-base.yml`, then yours (suggest calling it `20-something` aftewards.  Your Dockerfile should copy the contents of `host` and `container` to a directory that is the same name as the coniguration file, such as `20-something`.  Note that you can create multiple configuration files in the `conf.d` directory as long as they all start with the same prefix (`20-something-something` for example).  Every file copies is processed through ERB, therefore any required environment should be set in the /parasite-config.env file.
