# elementary OS on Raspberry Pi 4

⚠️ **The builds are not officialy supported by the elementary project** ⚠️

To download the official version visit [https://elementary.io/](https://elementary.io/)

## Special thanks

The builds are based on the work of James A. Chambers alias [TheRemote](https://github.com/TheRemote).
He has documented his work at https://jamesachambers.com/raspberry-pi-ubuntu-server-18-04-2-installation-guide/.
He makes his builds available at https://github.com/TheRemote/Ubuntu-Server-raspi4-unofficial.

## Download

Download the latest unofficial release for Raspberry Pi 4 from https://github.com/meisenzahl/elementary-os-unofficial/releases.

## Installation

As recommended by the Raspberry Pi Foundation use [balenaEtcher](https://www.balena.io/etcher/)
to flash the image to a SD card. The SD card should be at least 8 GB in size.

After you booted your Raspberry Pi 4 you are welcomed by the new [Initial Setup](https://github.com/elementary/initial-setup) process.

First you have to choose your language.

![Select Language](docs/screenshots/0000.png "Select Language")

Then you configure your keyboard layout.

![Keyboard Layout](docs/screenshots/0001.png "Keyboard Layout")

![Keyboard Layout](docs/screenshots/0002.png "Keyboard Layout")

Now it's time to create an account.

![Create an Account](docs/screenshots/0003.png "Create an Account")

![Enter your account information](docs/screenshots/0004.png "Enter your account information")

After you click **Finish Setup** you are welcomed by the new [Greeter](https://github.com/elementary/greeter).

![Greeter](docs/screenshots/0005.png "Greeter")

When you login you get your beloved elementary OS desktop.

![Desktop](docs/screenshots/0006.png "Desktop")

If you open **About** in **System Settings** you see that you are running on a Raspberry Pi.
Mine has 4 GB of RAM.

![About](docs/screenshots/0007.png "About")

The initial size for the operating system can be increased.
`raspi-config` is available for this purpose.

![Size after installation](docs/screenshots/0008.png "Size after installation")

For this you have to start `raspi-config` with root privileges.

![sudo raspi-config](docs/screenshots/0009.png "sudo raspi-config")

![raspi-config-1](docs/screenshots/0010.png "raspi-config-1")

Choose `7 Advanced Options - Configure advanced settings`.

![raspi-config-2](docs/screenshots/0011.png "raspi-config-2")

Choose `A1 Expand Filesystem - Ensures that all of the SD card storage is available to the OS`.

![raspi-config-3](docs/screenshots/0012.png "raspi-config-3")

You have to reboot to enlarge your filesystem.

![raspi-config-4](docs/screenshots/0013.png "raspi-config-4")

So choose to reboot now.

![raspi-config-5](docs/screenshots/0014.png "raspi-config-5")

After your Raspberry Pi 4 has booted up you can see that all storage is used.

![Size after raspi-config](docs/screenshots/0015.png "Size after raspi-config")

## Support

If you come across a problem open an [issue](https://github.com/meisenzahl/elementary-os-unofficial/issues).

## Building Locally

The following example uses Docker and assumes you have Docker correctly installed and set up:

 1) Run the build:

    ```
    mkdir -p artifacts
	docker run --privileged -i \
		-v /proc:/proc \
		-v ${PWD}/artifacts:/artifacts \
		-v ${PWD}:/working_dir \
		-w /working_dir \
		debian:latest \
		./build.sh
    ```

 2) When done, your image will be in the `artifacts` folder.
