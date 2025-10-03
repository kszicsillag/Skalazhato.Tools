```plaintext
# Install ansible, move rendered files into place and enable timer
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y ansible

# Move uploaded files into place
sudo mv /tmp/ansible-pull-runner.sh /usr/local/bin/ansible-pull-runner.sh
sudo mv /tmp/ansible-pull.service /etc/systemd/system/ansible-pull.service
sudo mv /tmp/ansible-pull.timer /etc/systemd/system/ansible-pull.timer

sudo chmod 0755 /usr/local/bin/ansible-pull-runner.sh
sudo systemctl daemon-reload
sudo systemctl enable --now ansible-pull.timer

```
