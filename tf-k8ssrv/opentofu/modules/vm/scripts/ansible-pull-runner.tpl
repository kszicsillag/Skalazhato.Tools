#!/bin/bash
set -euo pipefail

# Rendered ansible-pull runner script
ANSIBLE_REPO='${ANSIBLE_REPO}'
ANSIBLE_BRANCH='${ANSIBLE_BRANCH}'
ANSIBLE_PLAYBOOK='${ANSIBLE_PLAYBOOK}'

LOGFILE='/var/log/ansible-pull.log'

if [ -z "${ANSIBLE_REPO}" ]; then
  echo "ANSIBLE_REPO not set, exiting" >&2
  exit 1
fi

cd /var/tmp
/usr/bin/ansible-pull -U "$ANSIBLE_REPO" -C "$ANSIBLE_BRANCH" -i localhost "$ANSIBLE_PLAYBOOK" >> "$LOGFILE" 2>&1
