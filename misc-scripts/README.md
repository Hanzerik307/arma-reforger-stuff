# misc-scripts
Some misc scripts to use with Arma Reforger Linux Servers

* [monitor.service](monitor.service) and [monitor.sh](monitor.sh) Are currently used to restart the server after a match finish. Currently the server hangs and becomes un-joinable so it needs a restart. These files work together to monitor the journalctl logs of arma.service and will restart the arma.service when POSTGAME is detected.
