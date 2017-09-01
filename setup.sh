#!/bin/bash
################################################################################
# nginx <-> unix socket <-> uwsgi <-> Django <-> PostgreSQL
# Setup script for Django dev environment
#  * Database: PostgresSQL
#  * Django framework: (virtual environment)
#  * Web Server Gateway Interface: uWSGI (uwsgi running in virtual environment)
#  * Web Server: Nginx

################################################################################
## Config variables
virtenv=/opt/djangvenv
# Django superuser info
USER=${USER}
MAIL="admin@mail.com"

################################################################################
echo "========================================="
echo "Django Setup"
echo "-----------------------------------------"
echo -n "Site (project) name:     "
read -r djangProj
if [ ! "$djangProj" ]; then
    djangProj="project"
    printf "         Default set to: ${djangProj}\n"
fi
echo -n "Database name:           "
read -r djangdb
if [ ! "$djangdb" ]; then
    djangdb=${djangProj}
    printf "         Default set to: ${djangdb}\n"
fi
echo "Set up PostgresSQL user: ${USER}"
echo -n "Enter PSQL Password:     "
read -s PASSWORD0
printf "\nConfirm PSQL Password:   "
read -s PASSWORD
[ "$PASSWORD0" != "$PASSWORD" ] && printf "\nPasswords do not match!\n" && source $0
printf "\n"
echo "========================================="
echo "Verify Django info"
echo "Virtual environment:     ${virtenv}"
echo "Project name:            ${djangProj}"
echo "Database name:           ${djangdb}"
echo "Superuser name:          ${USER}"
echo "Superuser email:         ${MAIL}"
echo ""
echo "Enter password to continue with setup"
sudo -v

echo "Updating packages..."
## Check OS
thisos=$(cat /etc/*release | grep centos | head -n 1 | cut -d'=' -f2 - | sed s/\"//g )
# Ubuntu
if [ $thisos = "ubuntu" ]; then
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
    sudo apt-get -fy install python3-pip python3-dev python virtualenv postgresql nginx-full postgresql-contrib libpq-dev gcc
fi
# CentOS
if [ $thisos = "centos" ]; then
    # Experimental stuff for CentOS7 (these packages are older than the ones installed for Ubuntu 16.04)
    ## https://www.digitalocean.com/community/tutorials/how-to-serve-django-applications-with-uwsgi-and-nginx-on-centos-7
    sudo yum -y -v upgrade
    sudo yum -y -v install postgresql epel-release gcc
    sudo yum -y -v install nginx python34 python34-pip python34-devel 
    # sudo -H pip3 install --upgrade pip
    # sudo pip3 install requests bs4 lxml js2py # Web scraping
    # sudo pip3 install virtualenv virtualenvwrappers
    # # add to shell init script
    # # echo "export WORKON_HOME=~/Env" >> ~/.bashrc
    # # echo "source /usr/bin/virtualenvwrapper.sh" >> ~/.bashrc
    # sudo pip3 install setuptools wheel virtualenv django pytz psycopg2 uwsgi # django
    ## Set python3.4 as the default
    # echo "alias python='/usr/bin/python3.4'" >> ~/.bashrc
    # source ~/.bashrc
fi


echo "Upgrading pip..."
sudo -H pip3 install --upgrade pip

echo "Installing python django dependencies (globaly)..."
sudo -H pip3 install setuptools wheel virtualenv django pytz uwsgi psycopg2

echo "Configuring PostgresSQL database..."
printf "\n\nCreating PostgresSQL User: ${USER}...\n"
sudo -u postgres psql -c "CREATE USER ${USER} WITH LOGIN SUPERUSER CREATEDB CREATEROLE INHERIT REPLICATION CONNECTION LIMIT -1 PASSWORD '${PASSWORD}';"

printf "\nCreating PostgresSQL database: ${djangdb}...\n"
psql -c "CREATE DATABASE \"${djangdb}\" WITH OWNER = ${USER} ENCODING = 'UTF8' CONNECTION LIMIT = -1;" -d postgres
psql -c "GRANT ALL ON DATABASE \"${djangdb}\" TO ${USER};" -d postgres

echo "Creating Python VirtualEnv..."
echo "Setting up directory structure..."
sudo mkdir -p ${virtenv}
sudo chown -R ${USER}:${USER} ${virtenv}
mkdir -p ${virtenv}/static
cd ${virtenv}
virtualenv . -p python3

echo "Activating VirtualEnv..."
source ${virtenv}/bin/activate
echo "Setting up pip packages in VirtualEnv..."
pip3 install django
pip3 install uwsgi
pip3 install psycopg2

echo "Creating Django project..."
django-admin.py startproject ${djangProj}

echo "Deactivating VirtualEnv..."
deactivate
################################################################################
## Stuff for testing
# echo "Creating test file..."
# cd ${djangProj}
# touch test.py
# read -d '' test <<"EOF"
# # test.py
# def application(env, start_response):
#     start_response('200 OK', [('Content-Type','text/html')])
#     return [b"Hello World"]
# EOF
# echo test >> test.py
# echo "Running test..."
# uwsgi --http :8000 --wsgi-file test.py
# #################
# python manage.py runserver 0.0.0.0:8000
################################################################################
echo "Configuring Django settings.py..."
cd ${virtenv}/${djangProj}/${djangProj}
echo "Setting DEBUG = False"
sed -i s/DEBUG\ =\ True/DEBUG\ =\ False/g settings.py
echo "Setting ALLOWED_HOSTS = ['*']"
sed -i s/ALLOWED_HOSTS\ =\ \\[\\]/ALLOWED_HOSTS\ =\ \\[\'\\*\'\\]/g settings.py

echo "Setting DATABASES to PostgresSQL"
read -d '' olddb <<"EOF"
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    }
}
EOF

read -d '' newdb <<"EOF"
DATABASES = {
	'default' : {
		'ENGINE': 'django.db.backends.postgresql_psycopg2',
		'NAME': '${djangdb}',
		'USER': '${USER}',
		'PASSWORD': '${PASSWORD}',
		'HOST': 'localhost',
		'PORT': ''
	}
}
EOF
newdba="${newdb/\$\{djangdb\}/$djangdb}"
newdbb="${newdba/\$\{USER\}/$USER}"
newdbc="${newdbb/\$\{PASSWORD\}/$PASSWORD}"

a=0
replace=0
match=DATABASES
echo "" > settings2.py
IFS=''
while read line
    do a=$((a+1));
    if [[ $line == *"${match}"* ]] ; then
        c=$((a+6)) ;
        replace=1 ;
        echo "${newdbc}" >> settings2.py
    fi
    if [ $replace == 1 ] ; then
        if [ $a == $c ] ; then
            replace=0
        fi
    else
        echo "$line" >> settings2.py
    fi
done < "settings.py"
rm settings.py
mv settings2.py settings.py

echo "Setting STATIC_ROOT"
echo "STATIC_ROOT = '${virtenv}/${djangProj}/static/'" >> settings.py
#echo "STATIC_ROOT = os.path.join(BASE_DIR, \"static/\")" >> settings.py
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
python3 manage.py collectstatic
echo "Making migrations..."
python3 manage.py makemigrations
echo "Migrating..."
python3 manage.py migrate
#############################
echo -n "Creating superuser..."
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
echo "Configuring uWSGI..."
cd ${virtenv}/${djangProj}

echo "Touching the sock in tmp..."
touch /tmp/uwsgi.sock

echo "Creating uwsgi_params..."
touch uwsgi_params
read -d '' uwparams <<"EOF"
uwsgi_param  QUERY_STRING       $query_string;
uwsgi_param  REQUEST_METHOD     $request_method;
uwsgi_param  CONTENT_TYPE       $content_type;
uwsgi_param  CONTENT_LENGTH     $content_length;

uwsgi_param  REQUEST_URI        $request_uri;
uwsgi_param  PATH_INFO          $document_uri;
uwsgi_param  DOCUMENT_ROOT      $document_root;
uwsgi_param  SERVER_PROTOCOL    $server_protocol;
uwsgi_param  REQUEST_SCHEME     $scheme;
uwsgi_param  HTTPS              $https if_not_empty;

uwsgi_param  REMOTE_ADDR        $remote_addr;
uwsgi_param  REMOTE_PORT        $remote_port;
uwsgi_param  SERVER_PORT        $server_port;
uwsgi_param  SERVER_NAME        $server_name;
EOF
echo "$uwparams" >> uwsgi_params

echo "Creating emperor.ini..."
#cd {$virtenv}/{$djangProj}
touch emperor.ini
read -d '' uwsgini <<"EOF"
[uwsgi]
# Django-related settings
# the base directory (full path)
chdir           = virtenvProj
# Django's wsgi file
module          = djangProj.wsgi
# the virtualenv (full path)
home            = virtenv
# process-related settings
master          = true
# maximum number of worker processes
processes       = 5
# the socket (use the full path to be safe)
socket		= /tmp/uwsgi.sock
# Fix sock permissions (better if 664)
chmod-socket    = 666
# clear environment on exit
vacuum          = true
# Python Plugin
plugins         = python3
EOF
echo "$uwsgini" >> emperor.ini
virtenvProj0="${virtenv}/${djangProj}"
virtenvProj="${virtenvProj0//\//\\/}"
echo "Setting base directory..."
sed -i s/virtenvProj/${virtenvProj}/g emperor.ini
echo "Setting wsgi file module..."
sed -i s/djangProj/${djangProj}/g emperor.ini
virtenv0="${virtenv//\//\\/}"
echo "Setting virtual environment home..."
sed -i s/virtenv/${virtenv0}/g emperor.ini

#############################
echo "Creating nginx config..."
touch ${djangProj}.conf
read -d '' uwsgnginx <<"EOF"
# The upstream component nginx needs to connect to
upstream wsgicluster {
    #server 127.0.0.1:8001;
    server unix://tmp/uwsgi.sock;
}

# Configuration of the server
server {
    listen 80;
    server_name _;
    charset utf-8;
    error_log virtenv/djangProj/data/log/error.log;
    access_log virtenv/djangProj/data/log/access.log;
    #access_log off;
    location / {
        include virtenv/djangProj/uwsgi_params;
        uwsgi_pass wsgicluster;
    }
    location /static {
        alias virtenv/djangProj/static;
    }
    #location -^/(img|js|css)/ {
    #    root virtenv/djangProj/public;
    #    expires 30d;
    #}
    #location = /favicon.ico {
    #    log_not_found off;
    #}
}
EOF
echo "$uwsgnginx" >> ${djangProj}.conf
echo "Modifying nginx config..."
sed -i s/virtenv/${virtenv0}/g ${djangProj}.conf
sed -i s/djangProj/${djangProj}/g ${djangProj}.conf
echo "Linking config to sites-enabled..."
sudo ln -s ${virtenv}/${djangProj}/${djangProj}.conf /etc/nginx/sites-enabled/.
echo "Removing nginx default site..."
sudo rm -f /etc/nginx/sites-enabled/default

################################################################################
# echo "Configuring vassals for uWSGI emperor..."
# echo "Creating folders for sites-available and sites-enabled..."
# sudo mkdir -p /etc/uwsgi/apps-available
# sudo mkdir -p /etc/uwsgi/apps-enabled
# #############################
# echo "Creating vassal configuration file..."
# sudo touch /etc/uwsgi/apps-available/${djangProj}.yml
# read -d '' vassalyml <<"EOF"
# uwsgi:
#     master: true
#     processes: 1
#     vacuum: true
#     chmod-socket: 666
#     uid: www-data
#     gid: www-data
#     plugins: python32
#     socket: /tmp/djangProj.sock
#     chdir: virtenv/djangProj
#     pythonpath: virtenv/djangProj
#     module: application
#     touch-reload: virtenv/djangProj/application.py
# EOF
# sudo echo "$vassalyml" >> /etc/uwsgi/apps-available/${djangProj}.yml
# echo "Modifying vassal config..."
# sudo sed -i s/virtenv/${virtenv0}/g /etc/uwsgi/apps-available/${djangProj}.yml
# sudo sed -i s/djangProj/${djangProj}/g /etc/uwsgi/apps-available/${djangProj}.yml

#############################
echo "Creating uWSGI service with systemd..."
sudo touch /etc/systemd/system/emperor.uwsgi.service
sudo chown $USER:$USER /etc/systemd/system/emperor.uwsgi.service
sudo touch /var/log/uwsgi.log
read -d '' uwsgisvc <<"EOF"
[Unit]
Description=uWSGI Emperor
After=syslog.target

[Service]
PIDFile=/run/uwsgi/uwsgi.pid
ExecStartPre=/bin/mkdir -p /run/uwsgi
#ExecStartPre=/bin/chown http:http /run/uwsgi
ExecStart=virtenv/bin/uwsgi --ini virtenv/djangProj/emperor.ini --enable-threads
RuntimeDirectory=uwsgi
Restart=always
KillSignal=SIGQUIT
Type=notify
StandardError=syslog
NotifyAccess=main

[Install]
WantedBy=multi-user.target
EOF
echo "$uwsgisvc" >> /etc/systemd/system/emperor.uwsgi.service
echo "Modifying paths in emperor.uwsgi.service..."
sudo sed -i s/virtenv/${virtenv0}/g /etc/systemd/system/emperor.uwsgi.service
sudo sed -i s/djangProj/${djangProj}/g /etc/systemd/system/emperor.uwsgi.service
echo "Checking emperor.uwsgi.service for errors..."
sudo chown root:root /etc/systemd/system/emperor.uwsgi.service
sudo systemd-analyze verify /etc/systemd/system/emperor.uwsgi.service
echo "Starting emperor.uwsgi.service..."
sudo service emperor.uwsgi start
echo "Restarting nginx service..."
sudo service nginx restart
echo "Setting emperor.uwsgi service to auto-start..."
sudo systemctl enable emperor.uwsgi.service
#sudo systemctl start emperor.uwsgi.service
#sudo initctl reload-Configuration
#update-alternatives --set uwsgi /usr/bin/uwsgi_python32
