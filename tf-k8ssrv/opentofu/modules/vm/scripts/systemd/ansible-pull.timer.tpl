[Unit]
Description=Timer for ansible-pull

[Timer]
Unit=ansible-pull.service
OnCalendar=${ansible_oncalendar}
Persistent=true

[Install]
WantedBy=timers.target
