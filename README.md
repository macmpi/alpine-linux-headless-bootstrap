# Deploy Alpine Linux on a headless system

[Alpine Linux documentation](https://docs.alpinelinux.org/user-handbook/0.1a/Installing/setup_alpine.html) assumes **initial setup** is carried-out on a system with a keyboard & display to interract with.\
However, there are many cases where one might want to deploy a headless system, only available through a network connection (ethernet, wifi or as USB ethernet gadget).

This repo provides an **overlay file** to initially boot such headless system (leveraging Alpine distro's `initramfs` feature): it starts a basic ssh server to log-into from another Computer, in order to then perform actual system setup.


## Install procedure:
Please follow [Alpine Linux Wiki](https://wiki.alpinelinux.org/wiki/Installation#Installation_Overview) to download & create installation media for the target platform.\
Tools provided here can be used on any plaform for any install modes (diskless, data disk, system disk).

Just add [**headless.apkovl.tar.gz**](https://github.com/macmpi/alpine-linux-headless-bootstrap/raw/main/headless.apkovl.tar.gz)[^1] overlay file at the root of Alpine Linux boot media (or onto any custom side-media) and boot-up the system.\
With default network interface definitions (and SSID/pass file if using wifi), system can then be accessed under `ssh` with: \
`ssh root@<IP>`\
(system IP address may be determined with any IP scanning tools such as `nmap`).

As with Alpine Linux initial bring-up, `root` account has no password initially (change that during setup!).\
From there, system install can be performed as usual with `setup-alpine` for instance (check [wiki](https://wiki.alpinelinux.org/wiki/Alpine_setup_scripts#setup-alpine) for details).


Add-on files may be added next to `headless.apkovl.tar.gz` to customise boostrapping configuration (sample files are provided):
- `wpa_supplicant.conf`[^2] (*mandatory for wifi usecase*): define wifi SSID & password.
- `interfaces`[^2] (*optional*): define network interfaces at will, if defaults DCHP-based are not suitable.
- `ssh_host_*_key*` (*optional*): provide custom ssh keys to be injected (may be stored), instead of using bundled ones[^1] (not stored).
- `unattended.sh`[^2] (*optional*): create custom automated deployment script to further tune & extend actual setup (backgrounded).


**Goody:** seamless USB bootstrapping for PiZero devices (or similar supporting USB ethernet gadget networking):\
Just add `dtoverlay=dwc2` in `usercfg.txt` (or `config.txt`), and plug-in USB cable to Computer port.\
With Computer set-up to share networking with USB interface as 10.42.0.1 gateway, one can log into device from Computer with:\
`ssh root@10.42.0.2`

Main execution steps are logged in `/var/log/messages`.

[^1]: About bundled ssh keys: as this package is essentially intended to **quickly bootstrap** system in order to configure it, it purposely embeds [some ssh keys](https://github.com/macmpi/alpine-linux-headless-bootstrap/tree/main/overlay/etc/ssh) so that bootstrapping is as fast as possible. Those (temporary) keys are moved in RAM /tmp, so they will **not be saved/reused** once permanent configuration is set (with or without ssh server voluntarily installed in permanent setup).

[^2]: These files are linux text files: Windows/macOS users need to use text editors supporting linux text line-ending (such as [notepad++](https://notepad-plus-plus.org/), BBEdit or any similar).


## How to customize ?
This repository may be forked/cloned/downloaded.\
Main script file is [`headless.start`](https://github.com/macmpi/alpine-linux-headless-bootstrap/blob/main/overlay/etc/local.d/headless.start).\
Execute `./make.sh` to rebuild `headless.apkovl.tar.gz` after changes.


## Credits
Thanks for the initial guides & scripts from @sodface and @davidmytton.

