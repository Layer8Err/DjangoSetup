#!/bin/bash
################################################################################
# Django in virtual environment
# Setup script for Django dev environment
#  * Database: Default Sqlite
#  * Django framework: (virtual environment)
#  * Web Server Gateway Interface and Web Server are Python

################################################################################
## Config variables
# $virtenv will be the virtual environment directory
virtenv=/home/${USER}/dev/django
# $mgmtdir will be where we put all the helper scripts 
mgmtdir=${virtenv}/django-mgmt

# Django superuser info
USER=${USER}
MAIL="admin@mail.com"

################################################################################
#installerdir=$( pwd ) # Setup previous located in root git directory
installerdir=$(eval "cd .. ; pwd")
## Check OS
thisos=$( cat /etc/*release | grep ID | head -n 1 | cut -d'=' -f2 - | sed s/\"//g )
thisos=$( echo $thisos | tr [:upper:] [:lower:])
#clear
echo "============================================"
echo "Django Dev Setup on $thisos"
echo "--------------------------------------------"
echo -n "Virtual environment path:   "
read -r uvirtenv
if [ ! "$uvirtenv" ]; then
    virtenv="$uvirtenv"
    printf "\n"
else
    printf "         Default set to:    ${virtenv}\n"
fi
echo -n "Site (project) name:        "
read -r djangProj
if [ ! "$djangProj" ]; then
    djangProj="project"
    printf "         Default set to:    ${djangProj}\n"
fi
echo    "Set up Django superuser:    ${USER}"
echo -n "Enter superuser Password:   "
read -s PASSWORD0
printf "\nConfirm superuser Password: "
read -s PASSWORD
[ "$PASSWORD0" != "$PASSWORD" ] && printf "\nPasswords do not match!\n" && source $0
printf "\n"
echo "============================================"
echo "-------------Verify Django info-------------"
echo "Virtual environment:        ${virtenv}"
echo "Project name:               ${djangProj}"
echo "Database name:              db.sqlite3"
echo "Superuser name:             ${USER}"
echo "Superuser email:            ${MAIL}"
echo "____________________________________________"
echo "---Enter password to continue with setup----"
sudo -v
echo "============================================"
echo "Updating packages..."
# Ubuntu / Debian
if [ $thisos != "centos" ]; then
    ## Check to see if dpkg is in use by the system
    dailytask=$(ps -ax | grep apt.systemd.daily | grep -v grep)
    waitnum=$(ps -ax | grep apt.systemd.daily | grep -v grep | wc -l)
    waitnum=${waitnum#0}
    #sudo fuser /var/lib/dpkg/lock
    if [ $waitnum > 0 ]; then
        taskpid=$(ps -ax | grep apt.systemd.daily | grep -v grep | awk '{print$1}')
        printf "\nWaiting for apt.systemd.daily task ${taskpid} to finish..."
        waitnum=$(ps -ax | grep apt.systemd.daily | grep -v grep | wc -l)
        waitnum=${waitnum#0}
        while [ ${waitnum} > 0 ]; do
            sleep 5
            printf "."
            waitnum=$(ps -ax | grep apt.systemd.daily | grep -v grep | wc -l)
            waitnum=${waitnum#0}
        done
    fi
    printf "\n"
    sudo apt-get update && sudo apt-get -y upgrade

    echo "Installing packages..."
    sudo apt-get -fy install python3-pip python3-dev python virtualenv gcc
fi
# CentOS
if [ $thisos = "centos" ]; then
    # Experimental stuff for CentOS7 (these packages are older than the ones installed for Ubuntu 16.04)
    ## https://www.digitalocean.com/community/tutorials/how-to-serve-django-applications-with-uwsgi-and-nginx-on-centos-7
    sudo yum -y -v upgrade
    sudo yum -y -v install epel-release gcc
    sudo yum -y -v install python34 python34-pip python34-devel 
    # Open ports for nginx
    #sudo firewall-cmd --permanent --zone=public --add-service=http
    #sudo firewall-cmd --permanent --zone=public --add-service=https
    #sudo firewall-cmd --reload
    sudo -H pip3 install --upgrade pip
    sudo pip3 install setuptools virtualenv virtualenvwrappers
fi

randpwd (){
    randlen=$(( ( RANDOM % ( 30 - 20 + 1) ) + 20 ))
    randpwd=$( cat /dev/urandom | tr -dc 'a-zA-Z0-9-_!@#$%=' | fold -w ${randlen} | head -n 1 | grep -i '[!@#$%^&*()_+{}|:<>?=]' )
    echo $randpwd
}
PGPASSWORD=$( randpwd )

echo "Upgrading pip..."
sudo -H pip3 install --upgrade pip

################################################################################
echo "Creating Python VirtualEnv..."
echo "Setting up directory structure..."
sudo mkdir -p ${virtenv}
sudo chown -R ${USER}:${USER} ${virtenv}

cd ${virtenv}
if [ $thisos = "centos" ]; then
    virtualenv ${virtenv} -p python3
else
    virtualenv . -p python3
fi

echo "Activating VirtualEnv..."
source ${virtenv}/bin/activate
echo "Upgrading VirtualEnv..."
pip3 install --upgrade virtualenv
echo "Setting up pip packages in VirtualEnv..."
pip3 install django

echo "Creating Django project..."
django-admin.py startproject ${djangProj}

echo "Deactivating VirtualEnv..."
deactivate
################################################################################
echo "Configuring Django settings.py..."
cd ${virtenv}/${djangProj}/${djangProj}
#Leaving DEBUG = True
#Leaving ALLOWED_HOSTS = []
echo "Setting STATIC_ROOT"
echo "STATIC_ROOT = os.path.join(BASE_DIR, \"static\")" >> settings.py
echo "...done modifying settings.py"
################################################################################
echo "Configuring Django project structure and configs..."
echo "Creating static folder..."
mkdir -p ${virtenv}/${djangProj}/static
echo "Creating logging folder..."
mkdir -p ${virtenv}/${djangProj}/data/log
echo "Activating virtual environment..."
cd ${virtenv}
source bin/activate
cd ${virtenv}/${djangProj}
echo "Collecting static..."
python3 manage.py collectstatic --noinput
echo "Making migrations..."
python3 manage.py makemigrations
echo "Migrating..."
python3 manage.py migrate
#############################
echo -n "Creating Django superuser..."
#python3 manage.py createsuperuser
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
deactivate
################################################################################

echo "Creating ${mgmtdir} for Django helper scripts..."
sudo mkdir -p ${mgmtdir}
sudo chown -R ${USER}:${USER} ${mgmtdir}
echo "Copying scripts in ${installerdir}/django-mgmt to ${mgmtdir} ..."
cp -v ${installerdir}/django-mgmt/*.sh ${mgmtdir}/.

echo "Saving Django site settings to django_settings.sh ..."
cd ${mgmtdir}
settingsfile=${mgmtdir}/django_settings.sh
touch ${settingsfile}
read -d '' djangsettings <<"EOF"
#!/bin/bash
# This settings file defines how Django was set up
# You can reference this script by using:
#  source django_settings.sh

EOF
echo "$djangsettings" >> ${settingsfile}
echo "virtenv=${virtenv}" >> ${settingsfile}
echo "project=${djangProj}" >> ${settingsfile}

echo "Setting management scripts to executible..."
chmod +x *.sh
