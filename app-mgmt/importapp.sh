#!/bin/bash

## Config variables
#virtenv=/opt/djangvenv
#project=djangsite

# Settings file that should have been created at setup
source django_settings.sh
################################################################################
echo "Full path of app to import: "
echo "(e.g. /tmp/django-appName-0.1.tar.gz)"
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

deactivate

if [ "$autoactivate" == "y" ]; then
    echo "Extracting ${appPath} to /tmp ..."
    tar -zxvf ${appPath} -C /tmp/.
    echo -n "Gathering package info..."
    extractedname=$( echo $appPath | sed -e s/.tar.gz// | rev | cut -d / -f 1 - | rev )
    cd /tmp/${extractedname}
    pkgname=$( cat setup.py | grep "name=" | sed -e s/name=// | cut -d , -f 1 - | sed -e s/\'// | sed -e s/\'// | rev | cut -d " " -f 1 - | rev )
    cd *.egg-info
    appname=$( cat top_level.txt )
    echo "...done"
    echo -n "Cleaning up package info..."
    rm -rf /tmp/${extractedname}
    echo "...done"
    echo -n "Changing settings.py to list ${appname} under INSTALLED_APPS..."
    cd ${virtenv}/${project}/${project}
    echo "" > settings2.py
    match=INSTALLED_APPS
    IFS=''
    addappstring=0
    while read line ; do
        if [ $addappstring == 1 ] ; then
            echo "    '${appname}'," >> settings2.py ;
            addappstring=0 ;
        fi
        if [[ $line == *"${match}"* ]] ; then
            addappstring=1 ;
        fi
        echo "$line" >> settings2.py
    done < "settings.py"
    tail -n +2 settings2.py > settings.py
    rm settings2.py
    echo "...done"
    echo -n "Updating urls.py to list ${appname} urls to include..."
    echo "" > urls2.py
    matchimport=$( cat urls.py | grep "django.conf.urls" | grep -v "Import the include" )
    foundinclude=$( echo $matchimport | grep "include" )
    if [ !foundinclude ]; then
        while read line ; do
            if [[ $line == *"${matchimport}" * ]] ; then
                echo "$line, include" >> urls2.py
            else
                echo "$line" >> urls2.py
            fi
        done < "urls.py"
        tail -n +2 urls2.py > urls.py
        rm urls2.py
    fi
    match="urlpatterns = ["
    addurlstring=0
    while read line ; do
        if [ $addurlstring == 1 ] ; then
            echo "    url(r'^$appname/', include('$appname.urls))," >> urls2.py
            addurlstring=0 ;
        fi
        if [[ $line == *"${match}"* ]] ; then
            addurlstring=1 ;
        fi
        echo "$line" >> urls2.py
    done < "urls.py"
    tail -n +2 urls2.py > urls.py
    rm urls2.py
    echo "...done"
else
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
fi