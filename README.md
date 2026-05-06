# Setup instructions 

1. Clone necessary repos
    - Poky          : https://github.com/yoctoproject/poky 
    - RaspberryPI   : git://git.yoctoproject.org/meta-raspberrypi
    - Navigate inside each of these repo directories, then checkout `scarthgap` branch
2. Create build container by running following commands
    - Navigate to project directory in terminal
    - `docker build -t poky-dev .`
3. Run the built container using following command
    - `docker run --rm -it   -e LOCAL_UID=$(id -u)   -e LOCAL_GID=$(id -g)   -v $(pwd):$(pwd):Z   poky-dev`
    - This will run the container in interactive mode
4. Navigate to the project directory inside container(same directory path as the host project directory)
5. Navigate to poky project directory and run following commands
    - `source oe-init-build-env`
    - This will create build direcotry and navigate inside it.
    - open conf/local.conf and set `MACHINE` as needed
        - For qemu emulation image, set to `qemux86_64`
        - For raspberrypi, set to `raspberrypi`
6. Navigate back to poky/build directory
    - Run `bitbake core-image-minimal` to build the image

7. Once build is complete, image will be available under `poky/build/tmp/deploy/images/qemux86-64` directory

## Automated setup script

This repository includes a helper script `yocto-setup.sh` to simplify the Docker build and Yocto build flow.

Examples:

- Build the Docker image:
  ```bash
  ./yocto-setup.sh docker-build
  ```
- Start an interactive build container:
  ```bash
  ./yocto-setup.sh shell
  ```
- Build the default Yocto image inside the container:
  ```bash
  ./yocto-setup.sh build
  ```
- Build a Raspberry Pi image:
  ```bash
  ./yocto-setup.sh build raspberrypi core-image-minimal
  ```

Available commands:

- `clone [branch]` — clone `poky` and `meta-raspberrypi` repositories, default branch `scarthgap`
- `docker-build` — build the `poky-dev` Docker image
- `shell` — run an interactive container with the repository mounted
- `build [machine] [image]` — run `bitbake` inside the container
- `all [branch]` — clone repos and build the Docker image
