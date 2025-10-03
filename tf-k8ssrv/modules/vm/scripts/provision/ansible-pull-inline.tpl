```plaintext

# Install ansible, move rendered files into place and enable timer
# Ensure we're running under bash so 'set -o pipefail' is supported
if [ -z "$${BASH_VERSION:-}" ]; then
	if command -v bash >/dev/null 2>&1; then
		exec bash "$0" "$@"
	else
		echo "bash not found; continuing under sh (pipefail not available)" >&2
	fi
fi
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
