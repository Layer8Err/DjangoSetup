#!/bin/bash
echo "Killing uwsgi..."
kill $(ps aux | grep 'bin/uwsgi' | awk '{print }')
