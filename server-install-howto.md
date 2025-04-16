---
title: Arma Reforger Linux Server Setup
author: Hanzerik307
date: April 16, 2025
---

# Intro
This guide is geared towards folks who want to self-host an Arma Reforger Game server on Linux. In this guide I'm going to describe how I installed my own self-hosted dedicated Linux (Debian Based) ArmaReforger Server. Mine is currently set up on a little BeeLink SER5 Pro AMD Ryzen 7 5850U, 32GB Ram, 500GB SSD, running headless next to my PS5. This guide should work with most .deb based systems like Debian, Linux Mint, and Ubuntu.

# What you will need

* A PC Debian based Linux OS (Maybe a VM on Windows will work, haven't tried)
* Static IP address for the server (Local Network i.e. 192.168.1.69)
* Steamcmd
* Some Type of basic text editor: vim, nano, note pad, gedit, etc

I do everything via ssh terminal, so these will all be console command instructions from here on out.

# Getting Started

Make sure your Debain 12 distro has the `non-free and non-free-firmware` repositories set up in your `/etc/apt/sources.list` this is for installing `steamcmd`. Ubuntu Server can use the commands a little bit further down in this guide without having to edit anything by hand.

Here is what it looks like on Debian 12 stable:
```
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
```

# Installing SteamCMD
## Debian 12
Update and upgrade anything that needs it. And then install SteamCMD. Since the steam app is i386, we have to enable support for it on a 64bit system OS.
```
sudo apt update
sudo apt upgrade
sudo apt install software-properties-common
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install steamcmd
```
## Ubuntu
```
sudo add-apt-repository multiverse
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install steamcmd
```

# Creating Steam and Server Installer files

Create a directory to install the server in. I'm using $HOME environmental variable just because is shorter then typing out the absolute paths. 
```
mkdir $HOME/arma
cd $HOME/arma
```
Now we're going to create a few files to automate the installing, updating, and validating of the game server files. In this file we're going to put in some commands for `steamcmd` to use when starting up. It's a good idea to keep the server files up to date, and to see if anything has changed. In this file we will put something like this. The `1874900` is the current stable release of the Arma Reforger Server.

Create a file named `steam.txt`
```
nano steam.txt
```
```
@ShutdownOnFailedCommand 1
login anonymous
app_update 1874900 validate
quit
```
To save the file (using nano editor)
```
ctrl+x then hit y and then enter to save.
```

Next we will create a bash script to install the server files. this script will work in conjunction with the `steaminit.txt` file we just created.

Create a file named `install.sh`
```
nano install.sh
```
```
#!/bin/bash
/usr/games/steamcmd +force_install_dir $HOME/arma +runscript $HOME/arma/steam.txt
```

Next we will make the actual script that will start steamcmd, update and validate server files, then start the Arma Reforger Server

Create a file named `start.sh`
```
nano start.sh
```
```
#!/bin/bash
# Install or Update game
$HOME/arma/install.sh
# Start server
$HOME/arma/ArmaReforgerServer -config=$HOME/arma/server.json -profile=$HOME/arma/profile -maxFPS 60
```

You will notice I use the $HOME environmental variable in these examples. You can see what your path would be in a terminal by typing `echo $HOME`. It should come back with something like `/home/<username>`. As long as you are starting everything as your user, $HOME should work in the scripts. Otherwise use absolute paths like `/home/<username>/arma`.

# Setting up the Server

Now we will create a server configuration file. This will be the configuration for how the server will run. There are a few more settings that can be used, but these are the basics of a JSON config file. There are more examples floating around on the Official wiki pages, Discord, websites, etc.

Create a file named `server.json`
```
nano server.json
```
```json
{
   "publicAddress":"YOUR_PUBLIC_IP",
   "publicPort":2001,
   "game":{
      "name":"YOUR_SERVER_NAME",
      "password":"",
      "passwordAdmin":"SET_ADMIN_PASSWORD_HERE",
      "admins":[
         
      ],
      "scenarioId":"{DAA03C6E6099D50F}Missions/24_CombatOps.conf",
      "maxPlayers":6,
      "visible":true,
      "crossPlatform":true,
      "gameProperties":{
         "serverMaxViewDistance":1500,
         "serverMinGrassDistance":50,
         "networkViewDistance":1000,
         "disableThirdPerson":false,
         "fastValidation":true,
         "battlEye":true,
         "VONDisableUI":false,
         "VONDisableDirectSpeechUI":false,
         "VONCanTransmitCrossFaction":false
      },
      "mods":[
         
      ]
   },
   "operating":{
      "lobbyPlayerSynchronise":true,
      "joinQueue":{
         "maxSize":2
      },
      "disableNavmeshStreaming":[
         
      ]
   }
}
```

You will need to put your public IP in the `publicAddress` field. This will be the IP address that players will connect to from the outside world. On a computer with a browser you can check one of the "Whats my IP" websites to find it. You will have to look at your router instructions on how to forward the ports (UDP `2001`) to the game servers IP on your internal network. This is where having a static IP (example: 192.168.1.69) for your internal private network assigned to the game server PC is needed. There are various ways to configure a static IP, on Debian 12 if you are running a bare install of the OS with no graphical desktop you can do this in `/etc/network/interfaces`. Ubuntu uses `netplan` or `NetworkManager`. Or if you run a GUI desktop, configure your network card for a static IP via the Network Settings/Connections application for your desktop.

# Picking a Scenario from the Official List

Modify the `scenarioId` field in the server config file and pick a scenario for the server to run.
```
{ECC61978EDCC2B5A}Missions/23_Campaign.conf (Conflict - Everon)
{59AD59368755F41A}Missions/21_GM_Eden.conf (Game Master - Everon)
{2BBBE828037C6F4B}Missions/22_GM_Arland.conf (Game Master - Arland)
{C700DB41F0C546E1}Missions/23_Campaign_NorthCentral.conf (Conflict - Northern Everon)
{28802845ADA64D52}Missions/23_Campaign_SWCoast.conf (Conflict - Southern Everon)
{94992A3D7CE4FF8A}Missions/23_Campaign_Western.conf (Conflict - Western Everon)
{FDE33AFE2ED7875B}Missions/23_Campaign_Montignac.conf (Conflict - Montignac)
{DAA03C6E6099D50F}Missions/24_CombatOps.conf (Combat Ops - Arland)
{C41618FD18E9D714}Missions/23_Campaign_Arland.conf (Conflict - Arland)
{DFAC5FABD11F2390}Missions/26_CombatOpsEveron.conf (Combat Ops - Everon)
{3F2E005F43DBD2F8}Missions/CAH_Briars_Coast.conf (Capture & Hold: Briars)
{F1A1BEA67132113E}Missions/CAH_Castle.conf (Capture & Hold: Montfort Castle)
{589945FB9FA7B97D}Missions/CAH_Concrete_Plant.conf (Capture & Hold: Concrete Plant)
{9405201CBD22A30C}Missions/CAH_Factory.conf (Capture & Hold: Almara Factory)
{1CD06B409C6FAE56}Missions/CAH_Forest.conf (Capture & Hold: Simon's Wood)
{7C491B1FCC0FF0E1}Missions/CAH_LeMoule.conf (Capture & Hold: Le Moule)
{6EA2E454519E5869}Missions/CAH_Military_Base.conf (Capture & Hold: Camp Blake)
{2B4183DF23E88249}Missions/CAH_Morton.conf (Capture & Hold: Morton)
```
# Firing it up

Now we need to install everything.
Make the `install.sh` and `start.sh` scripts executable
```
chmod 755 start.sh
chmod 755 install.sh
```
It might be a good idea to run just the `install.sh` script first to see if everything goes well.
```
cd $HOME/arma
./install.sh
```
This will log into steam, download, and validate the Arma Reforger Server files. If everything looks good, we can run the `start.sh` script.
```
./start.sh
```
The script will check with steam for any updates, then spit out a bunch of text as it starts up the game server. You should be able to join it via the server list (May take a moment to show up), or you can do a direct join by starting the game and using the direct join feature (I'm on PS5, so I'm not sure what it is on PC or XBOX). You can close the server by Ctrl+c. If you can join and everything looks good, then you're done with the basic setup and running the game server, you can move on to automating the process if you wish.

# Automating the Server Process

You can use a program like `tmux` or `screen` to be able to start the server then disconnect the ssh session and have it stay running when you logout. Personally I use a `systemd "--user"` service to run mine, which will also restart it if it fails for whatever reason. Below is an example of what my `arma.service` file contents look like and how to enable lingering. This will start the game server whenever the server PC itself starts using your Linux user. For a systemd `--user` level service you'll need to enable lingering for that user. Normally when a `--user` level service is started, it only stays running while that user is logged into the system. With lingering enabled, you can start the service and log out. Plus after the service has been `enabled` by the user, it will auto start after a full system reboot if lingering is enabled. For normal system wide systemd services, they are usually configured in `/etc/systemd`, but for a normal user they'll be configured in `$HOME/.config/systemd/user/`. So if these directories do not exist, then create them.
```
mkdir -p $HOME/.config/systemd/user
cd $HOME/.config/systemd/user
```
We're going to create the service file that will be used to start/stop/restart the server process. It's a good idea to use absolute paths in these files so systemd doesn't freak out. And you may notice that we use the `default-target` in the `WantedBy` section. That's because by default it is the system "runlevel" `--user` services are setup to run in. In system wide services, a lot of times the `WantedBy` target is `multi-user.target`. But for normal users `systemctl --user` services are limited to `default.target`.
```
nano arma.service
```
We're going to make it look like this:
```bash
[Unit]
Description=Arma Reforger Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/<username>/arma
ExecStart=/home/<username>/arma/start.sh
Restart=always

[Install]
WantedBy=default.target
```
Ok, that should be all you need as far as a service file goes. Now we need to enable it for use and enable lingering for the user so it will stay running when they log off.
Enable Lingering for the user (Must be a Sudoer or root for this next command)
```
sudo loginctl enable-linger <username>
```
Now to enable the service (Commands as your normal user)
```
systemctl --user daemon-reload
systemctl --user enable arma.service
```
Now you can fire up the service and hopefully everything starts up.
```
systemctl --user start arma.service
systemctl --user status arma.service
```
If everything is good, the `systemctl --user status arma.service`  will show something like this with a bunch of info.
```
username@localhost:~$ systemctl --user status arma.service 
● arma.service - Arma Reforger Server
     Loaded: loaded (/home/<username>/.config/systemd/user/arma.service; enabled; preset: enabled)
     Active: active (running) since Fri 2025-02-14 15:00:27 MST; 5h 10min ago
```
The commands to control the game server are:
```
systemctl --user start arma.service
systemctl --user stop arma.service
systemctl --user restart arma.service
systemctl --user status arma.service
```
You can test everything out by rebooting the whole PC and seeing if the game server starts automatically, and maybe logging in to your game server as Admin and issuing the `#shutdown` command and seeing if it auto restarts. You may also want to read up on `journalctl` for reading the server log files: `journalctl --user -u arma.service`.

This is the first time dealing with anything related to Steam, so hopefully you find this guide helpful, and that there are not too many spelling mistakes in here LOL :-)

