sudo apt-get update -y
sudo apt-get install -y software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y ansible git
# move uploaded runner into place and make executable
sudo mv /tmp/ansible-pull-runner.sh /usr/local/bin/ansible-pull-runner.sh
sudo chmod +x /usr/local/bin/ansible-pull-runner.sh
# install cron job to call the rendered runner directly
(sudo crontab -l 2>/dev/null; echo "${ansible_pull_cron} /usr/local/bin/ansible-pull-runner.sh") | sudo crontab -
sudo systemctl restart cron || true
