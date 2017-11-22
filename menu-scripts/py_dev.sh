#!/bin/bash
# This script should server certain dev functions for Django
#
# Currently only launch into django shell
virtenv=/opt/djangvenv
project=djangsite

cd ${virtenv}
echo "Activating Python Virtual Environment..."
source bin/activate
cd ${project}
echo "Launching interactive Django shell..."
python3 manage.py shell
