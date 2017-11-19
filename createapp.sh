#!/bin/bash
# You should have activated the virtual environment
# source bin/activate
# You should be in the root django project (site)
# directory

## Config variables
virtenv=/opt/djangvenv
project=djangsite

cd ${virtenv}
source bin/activate
cd ${project}

printf "\nNew Django app name: "
read -r DJANGAPP
python3 manage.py startapp ${DJANGAPP}
echo "                app: ${DJANGAPP} created"
printf "Activate ${DJANGAPP} in ${project}? [y/N]: "
read -r ACTIVATEAPP
activate=$( echo ${ACTIVATEAPP:0:1} | tr [:upper:] [:lower:] )
if [ $activate == "y" ]; then
    ## Need to modify settings.py in project to list the app under INSTALLED_APPS
    appconfigname=$( echo ${DJANGAPP:0:1} | tr [:lower:] [:upper:] )$( echo ${DJANGAPP:1} | tr [:upper:] [:lower:] )Config
    installedappsstring=$DJANGAPP.apps.$appconfigname
    cd ${virtenv}/${project}/${project}
    echo "" > settings2.py
    addappstring=0
    match=INSTALLED_APPS
    IFS=''
    while read line ; do
        if [ $addappstring == 1 ] ; then
            echo "    '${installedappsstring}'," >> settings2.py ;
            addappstring=0 ;
        fi
        if [[ $line == *"${match}"* ]] ; then
            addappstring=1 ;
        fi
        echo "$line" >> settings2.py
    done < "settings.py"
    # Handle white space at the beginning of settings2.py
    tail -n +2 settings2.py > settings.py
    rm settings2.py
fi

deactivate