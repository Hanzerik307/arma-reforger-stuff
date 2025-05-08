# service-files
Example systemd --user service files. You should be able to modify to your needs. 
To use as a normal user you should probably enable lingering for the user running the server
```
sudo loginctl enable-linger username
```
* [arma.service](arma.service) Basic service file to run the Reforger server as a user service in the background. When lingering is enabled for the user, the server will stay running when the user logs out. If lingering is not enabled, then the server will stop as soon as the user logs out. With lingering enabled, the server will restart even when the host reboots.
* [restart.service](restart.service) and [restart.timer](restart.timer) Service and Timer file to provide a daily restart of the game server (arma.service).


```
systemctl --user daemon-reload
systemctl --user enable arma.service
systemctl --user start arma.service
systemctl --user status arma.service

Others:
systemctl --user stop arma.service
systemctl --user restart arma.service
```
