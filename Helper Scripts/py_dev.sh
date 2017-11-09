#!/bin/bash
# This script should server certain dev functions for Django
#
# Currently only launch into django shell
cd /opt/project
echo "Activating Python Virtual Environment..."
source bin/activate
cd djangSchedule
echo "Launching interactive Django shell..."
python3 manage.py shell
