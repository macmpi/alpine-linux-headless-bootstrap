# Bootstrap Alpine Linux on a headless system

[Alpine Linux documentation](https://docs.alpinelinux.org/user-handbook/0.1a/Installing/setup_alpine.html) assumes **initial setup** is carried-out on a system with a keyboard & display to interract with.\
However, in many cases one might want to deploy a headless system that is only available through a network connection (ethernet, wifi or as USB ethernet gadget).

This repo provides an **overlay file** to initially bootstrap[^1] a headless system (leveraging Alpine distro's `initramfs` feature): it starts a ssh server to log-into from another Computer, so that actual install on fresh system (or rescue on existing disk-based system) can then be performed remotely.


## Setup procedure:
Please follow [Alpine Linux Wiki](https://wiki.alpinelinux.org/wiki/Installation#Installation_Overview) to download & create installation media for the target platform.\
Tools provided here can be used on any plaform for any install modes (diskless, data disk, system disk).

Just add [**headless.apkovl.tar.gz**](https://github.com/macmpi/alpine-linux-headless-bootstrap/raw/main/headless.apkovl.tar.gz)[^2] overlay file at the root of Alpine Linux boot media (or onto any custom side-media) and boot-up the system.\
With default network interface definitions (and SSID/pass file if using wifi), system can then be remotely accessed with: `ssh root@<IP>`\
(system IP address may be determined with any IP scanning tools such as `nmap`).

As with Alpine Linux initial bring-up, `root` account has no password initially (change that during setup!).\
From there, actual system install can be performed as usual with `setup-alpine` for instance (check [wiki](https://wiki.alpinelinux.org/wiki/Alpine_setup_scripts#setup-alpine) for details).


Extra files may be added next to `headless.apkovl.tar.gz` to customise boostrapping configuration (check sample files):
- `wpa_supplicant.conf`[^3] (*mandatory for wifi usecase*): define wifi SSID & password.
- `interfaces`[^3] (*optional*): define network interfaces at will, if defaults DCHP-based are not suitable.
- `ssh_host_*_key*` (*optional*): provide custom ssh keys to be injected (may be stored), instead of using bundled ones[^2] (not stored). Providing an empty key file will trigger new keys generation (ssh server may take longer to start).
- `unattended.sh`[^3] (*optional*): create custom automated deployment script to further tune & extend actual setup (backgrounded).


**Goody:** seamless USB-ethernet gadget boostrapping (PiZero for instance):\
On supporting Pi devices, just add `dtoverlay=dwc2` in `usercfg.txt` (or `config.txt`), and plug USB cable into Computer port.\
With Computer set-up to share networking with USB interface as 10.42.0.1 gateway, one can log into device from Computer with: `ssh root@10.42.0.2`

Main execution steps are logged in `/var/log/messages`.

[^1]: Initial boot fully preserves system's original state (config files & installed packages): a fresh system will therefore come-up as unconfigured.

[^2]: About bundled ssh keys: this overlay is meant to **quickly bootstrap** system in order to then proceed with proper install; therefore it purposely embeds [some ssh keys](https://github.com/macmpi/alpine-linux-headless-bootstrap/tree/main/overlay/etc/ssh) so that bootstrapping is as fast as possible. Those temporary keys are moved in RAM /tmp: they will **not be stored/reused** once actual system install is performed (whether or not ssh server is installed in final setup).

[^3]: These files are linux text files: Windows/macOS users need to use text editors supporting linux text line-ending (such as [notepad++](https://notepad-plus-plus.org/), BBEdit or any similar).


## How to customize ?
This repository may be forked/cloned/downloaded.\
Main script file is [`headless.start`](https://github.com/macmpi/alpine-linux-headless-bootstrap/blob/main/overlay/etc/local.d/headless.start).\
Execute `./make.sh` to rebuild `headless.apkovl.tar.gz` after changes.


## Credits
Thanks for the initial guides & scripts from @sodface and @davidmytton.

