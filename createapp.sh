#!/bin/bash
# You should have activated the virtual environment
# source bin/activate
# You should be in the root django project (site)
# directory

## Config variables
virtenv=/opt/djangvenv

cd ${virtenv}
source bin/activate

printf "\nNew Django app name: "
read -r DJANGAPP
python3 manage.py startapp

deactivate