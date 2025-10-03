sudo apt-get update -y
sudo apt-get install -y software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y ansible git
# move uploaded runner into place and make executable
sudo mv /tmp/ansible-pull-runner.sh /usr/local/bin/ansible-pull-runner.sh
sudo chmod +x /usr/local/bin/ansible-pull-runner.sh

# move uploaded service and timer into place
sudo mv /tmp/ansible-pull.service /etc/systemd/system/ansible-pull.service
sudo mv /tmp/ansible-pull.timer /etc/systemd/system/ansible-pull.timer
sudo chmod 644 /etc/systemd/system/ansible-pull.service
sudo chmod 644 /etc/systemd/system/ansible-pull.timer

# reload systemd and enable timer
sudo systemctl daemon-reload
sudo systemctl enable --now ansible-pull.timer
