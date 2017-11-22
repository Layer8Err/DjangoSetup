#!/bin/bash

## Config variables
#virtenv=/opt/djangvenv
#project=djangsite

# Settings file that should have been created at setup
source django_settings.sh
################################################################################
echo -n "Full path of app to import: "
read -r appPath
#appPath=/opt/apps/myapp.tar.gz

cd ${virtenv}
source ${virtenv}/bin/activate
pip3 install ${appPath}

cd ${virtenv}/${project}
python3 manage.py collectstatic
python3 manage.py migrate

echo "You may need to add the app to settings.py and urls.py:"
echo "settings.py:"
echo "INSTALLED_APPS = ["
echo "    'appName.apps.AppnameConfig',"
echo ""
echo "urls.py:"
echo "from django.conf.urls import include, url"
echo "from django.contrib import admin"
echo ""
echo "urlpatterns = ["
echo "    url(r'^appname/', include('appName.urls')),"
echo ""

deactivate