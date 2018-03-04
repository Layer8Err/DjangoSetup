#!/bin/bash
# You should have activated the virtual environment
# source bin/activate
# You should be in the root django project (site)
# directory

## Config variables
#virtenv=/opt/djangvenv
#project=djangsite
MAIL="admin@mail.com"

# Settings file that should have been created at setup
source django_settings.sh

cd ${virtenv}
source bin/activate
cd ${project}

printf "\nNew superuser name: "
read -r USERNAME

printf "\nNew superuser pass: "
read -s PASSWORD
printf "\n"

script="
from django.contrib.auth.models import User;

username = '$USER';
password = '$PASSWORD';
email = '$MAIL';

if User.objects.filter(username=username).count()==0:
    User.objects.create_superuser(username, email, password);
    print('...Superuser created');
else:
    print('...Superuser creation skipped');
"
printf "$script" | python3 manage.py shell
#############################
echo "Deactivating virtual environment..."