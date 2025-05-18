# ArmaR Server Control GUI
I figured there are some folks who run Linux, but that may be intimidated by the Cli.
So I started thinking about this type of gui script. Here you will find a python3-pyqt5 script that I have worked on to make it very easy to start/stop/restart an Arma Reforger server.  Configure the important things within the server.json, add/remove mods from the server configuration, modify start-up parameters. All from the comfort of a game server which is installed on a system running a Desktop Environment. Just a reminder that these scripts and intructions are geared towards a user who is self-hosting on their own equipment.

If you followed my How-To, to include setting up your server as a `systemd --user service`, this should work just fine for a server running on a Debian/Ubuntu System with a desktop environment.
You will need to install `python3-pyqt5` and `jq` for this to work. Most systems will already have `systemd` installed by default. Please ensure `jq` is installed before trying to use this script; I need to put a dependency check in the script because it will zero out your server json if you don't have jq installed and try to save changes.
```
sudo apt update
sudo apt upgrade
sudo apt install python3-pyqt5 jq --no-install-recommends
```

chmod 755 armar-sc-gui.py

Python script can go in in `~/bin`

Desktop file would go in `~/.local/share/applications/`

Icon will would go in `~/.local/share/icons/`
