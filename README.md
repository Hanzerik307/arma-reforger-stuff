# arma-reforger-stuff
Stuff For Arma Reforger Linux Servers

I do have a [How-to](server-install-howto.md) on installing a basic Arma Reforger Game Server

The [armar-sc.sh](armar-sc.sh) script is still a work in progress. It works great if you followed the [How-to](server-install-howto.md), but could be modified to use with other server installs. The [armar-sc-gui](armar-sc-gui) is a Python script with a GUI interface for users who may be hosting on a Linux Desktop. Currently the text version only has one dependency `jq`, and that is not needed if you don't want the ability to configure the server.json. The GUI version has two dependencies `jq` and `python3-pyqt5`.

These scripts are set up to use directories and files and file structure described in the [How-To](server-install-howto.md), but should be able to be modified to work with different paths.
