#!/bin/bash
echo "Starting uwsgi emperor daemon..."
echo "Must be run as sudo"
exec /usr/local/bin/uwsgi --emperor /etc/uwsgi/vassals --uid www-data --gid www-data --daemonize /var/log/uwsgi-emperor.log
