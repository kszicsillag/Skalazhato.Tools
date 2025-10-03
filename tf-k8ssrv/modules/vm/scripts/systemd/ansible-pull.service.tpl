[Unit]
Description=Run ansible-pull

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ansible-pull-runner.sh

