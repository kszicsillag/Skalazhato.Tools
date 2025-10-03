#!/bin/sh
# set -eu

# Install ansible and deploy the rendered systemd unit and runner script
sudo apt-get update -y
sudo apt-get install -y ansible

# Move uploaded files into place (use -f to overwrite existing files)
sudo mv -f /tmp/ansible-pull-runner.sh /usr/local/bin/ansible-pull-runner.sh
sudo mv -f /tmp/ansible-pull.service /etc/systemd/system/ansible-pull.service
sudo mv -f /tmp/ansible-pull.timer /etc/systemd/system/ansible-pull.timer

sudo chmod 0755 /usr/local/bin/ansible-pull-runner.sh
sudo systemctl daemon-reload
sudo systemctl enable --now ansible-pull.timer
