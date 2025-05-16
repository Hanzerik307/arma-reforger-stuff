#!/bin/bash

# Install or Update game - Uncomment line below to enable the option to update steam and server files when the server starts.
# $HOME/arma/install.sh

# Start server - Updated format to work with my GUI version functions.
$HOME/arma/ArmaReforgerServer \
  -config=$HOME/arma/server.json \
  -profile=$HOME/arma/profile \
  -maxFPS=60 \
  -logStats=60000 \
  -keepNumOfLogs=5 \
  -autoReload=30 \
  -autoShutdown
