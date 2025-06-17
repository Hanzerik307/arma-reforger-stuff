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


![Screenshot from 2025-06-17 12-02-16](https://github.com/user-attachments/assets/8d2ec9d2-e98d-4f55-b024-11c17dbbaf6d)

![Screenshot from 2025-06-17 12-02-34](https://github.com/user-attachments/assets/45219ea4-be89-480d-a79a-da5eddc39f27)

![Screenshot from 2025-06-17 12-02-46](https://github.com/user-attachments/assets/b6e74cb4-462f-4fc3-a05a-da7b4db4019f)

![Screenshot from 2025-06-17 12-02-56](https://github.com/user-attachments/assets/1e7b9198-eb60-4f88-a49e-b53f4664c26d)

