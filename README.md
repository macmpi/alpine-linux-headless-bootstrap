# Deploy Alpine Linux on a headless system

[Alpine Linux documentation](https://docs.alpinelinux.org/user-handbook/0.1a/Installing/setup_alpine.html) assumes one can interract with system directly with a keyboard & display.\
However, there are many cases where one might want to deploy a headless system, only available through a network connection (ethernet, wifi or as USB ethernet gadget).

This repo provides an overaly file to initially boot the headless system (leveraging Alpine distro's `initramfs` feature): it enables a basic ssh server to log-into from another Computer, in order to finalize system set-up.


## Install procedure:
Please follow [Alpine Linux Wiki](https://wiki.alpinelinux.org/wiki/Installation#Installation_Overview) to download & create installation media for the chosen platform.\
Tools provided here can be used on any plaform for any install modes (diskless, data disk, system disk).

Just add [**headless.apkovl.tar.gz**](https://github.com/macmpi/alpine-linux-headless-bootstrap/raw/main/headless.apkovl.tar.gz) overlay file at the root of Alpine Linux boot media (or onto any writeable side-media, e.g. the secondary partition of x86_64 ISO containing EFI files) and boot the system.

With default network interface definitions (and optional wifi SSID/pass file), one may then access the system under `ssh` with:\
`ssh root@<IP>`  (system IP address may be determined with any IP scanning tools such as `nmap`).

As with Alpine Linux initial bring-up, `root` account has no password initially (change that after setup!).\
From there, system install can be fine-tuned as usual with `setup-alpine` for instance (check [wiki](https://wiki.alpinelinux.org/wiki/Alpine_setup_scripts#setup-alpine) for details).


Optional files can be added next to `headless.apkovl.tar.gz` to customise setup (sample files are provided):
- `wpa_supplicant.conf`: define wifi SSID & password (mandatory for wifi usecase).
- `interfaces`: define network interfaces at will, if defaults DCHP-based are not suitable.
- `unattended.sh`: make custom automated deployment script to further tune & extend setup (backgrounded).

*Note:* these files are linux text files: Windows/macOS users need to use text editors supporting linux text line-ending (such as [notepad++](https://notepad-plus-plus.org/), BBEdit or any other).

Main execution steps are logged in `/var/log/messages`.


## How to customize further ?
This repository may be forked/cloned/downloaded.\
Main script file is [`headless.start`](https://github.com/macmpi/alpine-linux-headless-bootstrap/blob/main/overlay/etc/local.d/headless.start).\
Execute `./make.sh` to rebuild `headless.apkovl.tar.gz`.

*Side note:* one nicety for bootstrapping PiZero devices, or similar which can support USB ethernet gadget networking.\
Just add `dtoverlay=dwc2` in `usercfg.txt` (or `config.txt`), and plug-in USB to Computer port.\
With Computer set-up to share networking with USB interface, device will appear at 10.42.0.2 onto Computer's subnet to log into !...


## Credits
Thanks for the original instructions & scripts from @sodface and @davidmytton.

