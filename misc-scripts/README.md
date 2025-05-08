# misc-scripts
Some misc scripts to use with Arma Reforger Linux Servers

* [monitor.service](monitor.service) and [monitor.sh](monitor.sh) Are currently used to restart the server after a match finish. Currently the server hangs and becomes un-joinable so it needs a restart. These files work together to monitor the journalctl logs of arma.service and will restart the arma.service when POSTGAME is detected.

* This can also now be achieved by using the `-autoshutdown` parameter in your start script. You would use something like `-autoreload=30 -autoshutdown` . This will give players 30sec to check out Postgame stats, then the game server will be kill/shutdown. If you used the instructions in the How-to, then your service will restart cleanly.
