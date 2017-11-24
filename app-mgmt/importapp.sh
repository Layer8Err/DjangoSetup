#!/bin/bash

## Config variables
#virtenv=/opt/djangvenv
#project=djangsite

# Settings file that should have been created at setup
source django_settings.sh
################################################################################
echo "Full path of app to import: "
echo "(e.g. /tmp/django-appName-0.1.tar.gz"
echo -n ":> "
read -r appPath
#appPath=/opt/apps/myapp.tar.gz
echo ""
echo -n "Do you want to attempt to auto-activate this app? [y/N]: "
read -r autoactivate
if [ ! "$autoactivate" ]; then
    autoactivate="n"
fi
autoactivate=$( echo $reinstall | tr [:upper:] [:lower:] )
autoactivate=${autoactivate:0:1}

cd ${virtenv}
source ${virtenv}/bin/activate
pip3 install ${appPath}

cd ${virtenv}/${project}
python3 manage.py collectstatic
python3 manage.py migrate

echo "You may need to add the app to settings.py and urls.py:"
echo "settings.py:"
echo "INSTALLED_APPS = ["
echo "    # 'appName.apps.AppnameConfig',"
echo "    'appName',"
echo ""
echo "urls.py:"
echo "from django.conf.urls import include, url"
echo "from django.contrib import admin"
echo ""
echo "urlpatterns = ["
echo "    url(r'^appname/', include('appName.urls')),"
echo ""

deactivate

if [ "$autoactivate" == "y" ]; then
    echo "Extracting ${appPath} to /tmp ..."
    tar -zxvf ${appPath} -C /tmp/.
    extractedname=$( echo $appPath | sed -e s/.tar.gz// | rev | cut -d / -f 1 - | rev )
    
fi