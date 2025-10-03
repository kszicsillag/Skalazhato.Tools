sudo apt-get update -y
sudo apt-get install -y software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y ansible git
# ensure envsubst is available for template rendering
sudo apt-get install -y gettext-base
# move uploaded runner into place and make executable
sudo mv /tmp/ansible-pull-runner.sh /usr/local/bin/ansible-pull-runner.sh
sudo chmod +x /usr/local/bin/ansible-pull-runner.sh
## Render templates uploaded under /tmp/tf-scripts using environment variables
# Export variables for envsubst to consume
export ANSIBLE_REPO='${ansible_repo}'
export ANSIBLE_BRANCH='${ansible_branch}'
export ANSIBLE_PLAYBOOK='${ansible_playbook_path}'
export ANSIBLE_ONCAL='${ansible_oncalendar}'

# Render service and timer templates
envsubst < /tmp/tf-scripts/ansible-pull-service.tpl > /tmp/ansible-pull.service
envsubst < /tmp/tf-scripts/ansible-pull-timer.tpl > /tmp/ansible-pull.timer

# move rendered files into place
sudo mv /tmp/ansible-pull.service /etc/systemd/system/ansible-pull.service
sudo mv /tmp/ansible-pull.timer /etc/systemd/system/ansible-pull.timer
sudo chmod 644 /etc/systemd/system/ansible-pull.service
sudo chmod 644 /etc/systemd/system/ansible-pull.timer

# reload systemd and enable timer
sudo systemctl daemon-reload
sudo systemctl enable --now ansible-pull.timer
