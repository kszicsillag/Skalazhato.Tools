[Unit]
Description=Timer for ansible-pull

[Timer]
OnCalendar=${ansible_oncalendar}
Persistent=true

[Install]
WantedBy=timers.target
