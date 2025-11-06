# Bootstrap Alpine Linux on a headless system

[Alpine Linux documentation](https://docs.alpinelinux.org/user-handbook/0.1a/Installing/setup_alpine.html) assumes **initial setup** is carried-out on a system with a keyboard & display.\
However, in many cases one might want to deploy a headless system that is only available through a network connection (ethernet, wifi or as USB ethernet gadget).

This repo provides an **overlay file** to initially bootstrap[^1] such headless system (leveraging Alpine distro's `initramfs` feature): it starts a ssh server to log-into from another Computer, so that actual install on fresh system (or rescue on existing disk-based system[^2]) can then be performed remotely.\
An optional script may also be launched during that same initial bootstrap, to perform fully automated setup.


## Setup procedure:
Please follow [Alpine Linux Wiki](https://wiki.alpinelinux.org/wiki/Installation#Installation_Overview) to download & create installation media for the target platform.\
Tools provided here can be used on any hardware platform to prepare for any install modes (diskless, data disk, system disk).

Just add [**headless.apkovl.tar.gz**](https://is.gd/apkovl_master) overlay file *as-is* at the root of Alpine Linux boot media (or onto any custom side-media) and boot-up the system.\
With default DCHP-based network interface definitions (and [SSID/pass](#extra-configuration) file if using wifi), system can then be remotely accessed with: `ssh root@<IP>`\
(system IP address may be determined with any IP scanning tools such as `nmap`).

As with Alpine Linux initial bring-up, `root` account has no password initially.\
From there, actual system install can be performed as usual with `setup-alpine` for instance (check Alpine [wiki](https://wiki.alpinelinux.org/wiki/Alpine_setup_scripts#setup-alpine) for details).

## Extra configuration:
Extra files may be added next to `headless.apkovl.tar.gz` to customise boostrapping configuration (check `sample_*` files):
- `wpa_supplicant.conf`[^3] (*mandatory for wifi*): define wifi SSID, password and regulatory country [code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
- `unattended.sh`[^3] (*optional*): provide a deployment script to automate setup & customizations during initial bootstrap *(check users' contributed [samples](https://github.com/macmpi/alpine-linux-headless-bootstrap/discussions/categories/unattended-sh-samples) and share yours)*.
- `interfaces`[^3] (*optional*): define network interfaces at will, if defaults DCHP-based are not suitable.
- `authorized_keys` (*optional*): provide client's public SSH key to secure `root` ssh login.
- `ssh_host_*_key*` (*optional*): provide server's custom ssh keys to be injected (may be stored), instead of using temporarily bundled ones[^4] (not stored). Providing an empty key file will trigger new keys generation (ssh server may take longer to start).
- `opt-out` (*optional*): dummy file to opt-out internet features (connection status, version check, auto-update) and related links usage anonymous [telemetry](https://is.gd/privacy.php).
- `auto-updt` (*optional*): enable automatic `headless.apkovl.tar.gz` file update with latest from master branch. If it contains `reboot` keyword all in one line, system will reboot after succesful update (unless ssh session is active or `unattended.sh` script is available).

Main execution steps are logged: `cat /var/log/messages | grep headless`.

## Goody for *OTG-peripheral* capable devices:
Seamless USB-gadget mode on *OTG-peripheral* capable devices (*e.g. on PiZero*): serial console, ethernet and mass-storage
- Make sure `dwc2` (or `dwc3`) driver is previously loaded on capable device, and configuration is set to **OTG peripheral** mode: this may be driven by hardware (including cable) and/or software.\
(on supporting Pi devices, just add `dtoverlay=dwc2,dr_mode=peripheral` in `usercfg.txt` (or `config.txt`) to force both by software)
- Plug USB cable into host Computer port before booting device.
  - serial terminal can then be connected-to from host Computer (e.g. `cu -l ttyACM0` on Linux. xon/xoff flow control).
  - alternatively, with host Computer ECM/RNDIS interface set-up as `10.42.0.1` (sharing internet or not), one can log into device from host with: `ssh root@10.42.0.2`.
  - volume containing `headless.apkovl.tar.gz` file may be accessed/mounted from host, and config files easily edited. Make sure to unmount properly before removing USB plug.

_Note:_ optionally, same USB-gadget feature may be easily enabled on final system by installing `xg_multi` Alpine [package](https://pkgs.alpinelinux.org/packages?name=xg_multi&branch=edge&repo=&arch=&origin=&flagged=&maintainer=) and service during system setup phase (refer to [`xg_multi`](https://github.com/macmpi/xg_multi/) project).

##
[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/macmpi)

## Want to tweak more ?
This repository may be forked/cloned/downloaded.\
Main script file is [`headless_bootstrap`](https://github.com/macmpi/alpine-linux-headless-bootstrap/tree/main/overlay/tmp/.ALHB/headless_bootstrap).\
Execute `./make_ALHB.sh` to rebuild `headless.apkovl.tar.gz` after changes.\
(requires `busybox`; check `busybox` build options if not running from Alpine or Ubuntu)

## Credits
Thanks for the initial guides & scripts from @sodface and @davidmytton.

[^1]: Initial boot fully preserves system's original state (config files & installed packages): a fresh system will therefore come-up as unconfigured.
[^2]: Temporarily remove `root=*` statement from kernel command-line parameters list to disable disk-based boot mode.
[^3]: These files are linux text files: Windows/macOS users need to use text editors supporting linux text line-ending (such as [notepad++](https://notepad-plus-plus.org/), BBEdit or any similar).
[^4]: About temporarily bundled ssh keys: this overlay is meant to **quickly bootstrap** system in order to then proceed with proper install; therefore it purposely embeds [some ssh keys](https://github.com/macmpi/alpine-linux-headless-bootstrap/tree/main/overlay/tmp/.ALHB) so that bootstrapping is as fast as possible. Those temporary keys are in RAM `/tmp`: they **are discarded** once actual system install is rebooted (whether or not ssh server is installed in final setup).
