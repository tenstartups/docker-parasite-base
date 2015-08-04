CoreOS Twelve-Factor Configuration Base Image
==

This project is a very opinionated set of procedures and scripts for running applications in CoreOS and Docker, with the fundamental aim of meeting the requirements of a twelve-factor application (http://12factor.net).

The opinionated part is born of having spent the past year configuring and maintaining several applications on CoreOS/Docker, working through the various kinks, and watching the technologies evolve and improve.

This Docker image is not meant to be used on its own, but instead should be used as the base image for your application's `coreos-12factor` project, which should follow a very specific directory structure, similar to that of this base image.

### CoreOS 12factor directory structure

    .
    ├── conf.d         # YAML instructions on how to deploy files in the host and container directories.
    ├── container      # Container (Docker) configurations files.
    |   ├── conf       # Configuration files for each specific container service.
    |   ├── env        # Environment files (*.env) used inside of container services
    |   └── script     # Bash scripts used inside of container services.
    ├── host           # Host (CoreOS) configuration files.
    |   ├── env.d      # Individual environment files (*.env) that are merged into single files for systemd, docker and bash profile.
    |   ├── init       # Core initialization scripts that are used to bootstrap a new machine (base image only).
    |   ├── init.d     # Additional initialization bash scripts (*.sh) or CoreOS cloud config (*.yml) run during stage two initialization.
    |   ├── script     # Bash scripts used in the host to perform various operations.
    |   ├── systemd    # Systemd unit descriptors for running all the services of your application.
    |   └── tools.d    # Individual tools installation scripts called by the tools-install systemd service on startup.
    ├── Dockerfile     # Source files (alternatively `lib` or `app`)
    └── README.md

In order to create your own application-specific CoreOS 12factor image you should follow the specified directory structure and then publish the image to a private docker registry that your server machines can contact on boot.  You will need to launch your CoreOS instances with a cloud-config that looks something like this.

```yaml
#cloud-config
hostname: <%= hostname %>

write_files:
  - path: /12factor-config.env
    permissions: '0644'
    content: |
      DOCKER_USERNAME=<%= docker_username %>
      DOCKER_EMAIL=<%= docker_email %>
      DOCKER_PASSWORD=<%= docker_password %>
      STAGE=<%= stage %>
      ROLE=<%= role %>
      DOCKER_IMAGE_12FACTOR_CONFIG=<%= docker_image %>
      CONFIG_DIRECTORY=<%= config_directory %>
      DATA_DIRECTORY=<%= data_directory %>

coreos:
  units:
    - name: 12factor-init-stage-one.service
      command: start
      runtime: yes
      content: |
        [Unit]
        Description=CoreOS twelve-factor stage one initialization
        Requires=systemd-networkd.service docker.service
        After=systemd-networkd.service docker.service

        [Service]
        User=root
        Type=oneshot
        RemainAfterExit=true
        EnvironmentFile=/12factor-config.env
        EnvironmentFile=-/12factor-config-ext.env
        ExecStartPre=/usr/bin/bash -c "[ -f '/root/.dockercfg' ] || docker login -u ${DOCKER_USERNAME} -e ${DOCKER_EMAIL} -p ${DOCKER_PASSWORD}"
        ExecStartPre=/usr/bin/docker run --rm \
          -v /var/run/${CONFIG_DIRECTORY}:${CONFIG_DIRECTORY} \
          --env-file=/etc/environment \
          --env-file=/12factor-config.env \
          --net host \
          ${DOCKER_IMAGE_12FACTOR_CONFIG} \
          host
        ExecStart=/usr/bin/sh -c "/var/run/${CONFIG_DIRECTORY}/init/stage-one"
```

The key requirements are to set the server hostname (FQDN) and create a systemd unit that logs into your Docker registry, runs your CoreOS 12factor image in host mode, then launchs the 12factor stage one initialization script.
