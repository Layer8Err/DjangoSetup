#!/bin/bash
################################################################################
# nginx <-> unix socket <-> uwsgi <-> Django <-> PostgreSQL
# Setup script for Django production environment
#  * Database: PostgresSQL
#  * Django framework: (virtual environment)
#  * Web Server Gateway Interface: uWSGI (uwsgi running in virtual environment)
#  * Web Server: Nginx

################################################################################
## Config variables
# $virtenv will be the virtual environment directory
virtenv=/opt/djangvenv
# $mgmtdir will be where we put all the helper scripts 
mgmtdir=/opt/django-mgmt

# Django superuser info
USER=${USER}
MAIL="admin@mail.com"

################################################################################
#installerdir=$( pwd ) # Setup previously located in root git directory
installerdir=$(eval "cd .. ; pwd")

## Check OS
thisos=$( cat /etc/*release | grep ID | head -n 1 | cut -d'=' -f2 - | sed s/\"//g )
thisos=$( echo $thisos | tr [:upper:] [:lower:])
clear
echo "============================================"
echo "Django Setup on $thisos"
echo "--------------------------------------------"
echo -n "Site (project) name:        "
read -r djangProj
if [ ! "$djangProj" ]; then
    djangProj="project"
    printf "         Default set to:    ${djangProj}\n"
fi
echo -n "Database name:              "
read -r djangdb
if [ ! "$djangdb" ]; then
    djangdb=${djangProj}
    printf "         Default set to:    ${djangdb}\n"
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
echo "Database name:              ${djangdb}"
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
    sudo apt-get -fy install python3-pip python3-dev python virtualenv postgresql nginx-full postgresql-contrib libpq-dev gcc
fi
# CentOS
if [ $thisos = "centos" ]; then
    # Experimental stuff for CentOS7 (these packages are older than the ones installed for Ubuntu 16.04)
    ## https://www.digitalocean.com/community/tutorials/how-to-serve-django-applications-with-uwsgi-and-nginx-on-centos-7
    sudo yum -y -v upgrade
    sudo yum -y -v install postgresql postgresql-server postgresql-contrib epel-release gcc
    sudo yum -y -v install nginx python34 python34-pip python34-devel 
    # Open ports for nginx
    sudo firewall-cmd --permanent --zone=public --add-service=http
    sudo firewall-cmd --permanent --zone=public --add-service=https
    sudo firewall-cmd --reload
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
    sudo postgresql-setup initdb
    echo "Modify pg_hba.conf to allow password login..."
    sudo sed -i s/ident/md5/g /var/lib/pgsql/data/pg_hba.conf
    echo "Enabling PostgreSQL service..."
    sudo systemctl enable postgresql
    echo "Starting PostgreSQL service..."
    sudo systemctl start postgresql
fi

randpwd (){
    randlen=$(( ( RANDOM % ( 30 - 20 + 1) ) + 20 ))
    randpwd=$( cat /dev/urandom | tr -dc 'a-zA-Z0-9-_!@#$%=' | fold -w ${randlen} | head -n 1 | grep -i '[!@#$%^&*()_+{}|:<>?=]' )
    echo $randpwd
}
PGPASSWORD=$( randpwd )

echo "Upgrading pip..."
sudo -H pip3 install --upgrade pip

echo "Installing python django dependencies (globaly)..." # not needed since we install to virtualenv
sudo -H pip3 install setuptools wheel virtualenv pytz

echo "Configuring PostgresSQL database..."
printf "\n\nCreating PostgresSQL User: ${USER}...\n"
sudo -u postgres psql -c "CREATE USER ${USER} WITH LOGIN SUPERUSER CREATEDB CREATEROLE INHERIT REPLICATION CONNECTION LIMIT -1 PASSWORD '${PGPASSWORD}';"

printf "\nCreating PostgresSQL database: ${djangdb}...\n"
psql -c "CREATE DATABASE \"${djangdb}\" WITH OWNER = ${USER} ENCODING = 'UTF8' CONNECTION LIMIT = -1;" -d postgres
psql -c "GRANT ALL ON DATABASE \"${djangdb}\" TO ${USER};" -d postgres

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
pip3 install django uwsgi psycopg2

echo "Creating Django project..."
django-admin.py startproject ${djangProj}

echo "Deactivating VirtualEnv..."
deactivate
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
newdbc="${newdbb/\$\{PASSWORD\}/$PGPASSWORD}"

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
            replace=0 ;
        fi
    else
        if [ $a -gt 0 ] ; then
            echo "$line" >> settings2.py
        fi
    fi
done < "settings.py"
# Handle white space at the beginning of settings2.py
tail -n +2 settings2.py > settings.py
rm settings2.py

echo "Setting STATIC_ROOT"
#echo "STATIC_ROOT = '${virtenv}/${djangProj}/static/'" >> settings.py
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

echo "Creating uwsgi.ini..."
#cd {$virtenv}/{$djangProj}
touch uwsgi.ini
if [ $thisos != "centos" ]; then
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
else
read -d '' uwsgini <<"EOF"
[uwsgi]
project         = djangProj
username        = thisuser
base            = virtenv

chdir           = virtenvProj
home            = virtenv
module          = djangProj.wsgi:application

master          = true
processes       = 5

uid             = thisuser
socket		    = /run/uwsgi/djangProj.sock
chown-socket    = thisuser:nginx
chmod-socket    = 660
vacuum          = true
EOF
sudo mkdir -p /etc/uwsgi/sites
fi
echo "$uwsgini" >> uwsgi.ini
virtenvProj0="${virtenv}/${djangProj}"
virtenvProj="${virtenvProj0//\//\\/}"
echo "Setting base directory..."
sed -i s/virtenvProj/${virtenvProj}/g uwsgi.ini
echo "Setting wsgi file module..."
sed -i s/djangProj/${djangProj}/g uwsgi.ini
virtenv0="${virtenv//\//\\/}"
echo "Setting virtual environment home..."
sed -i s/virtenv/${virtenv0}/g uwsgi.ini
if [ $thisos = "centos" ]; then
    echo "Setting user in uwsgi.ini..."
    sed -i s/thisuser/${USER}/g uwsgi.ini
    echo "Linking ini to /etc/uwsgi/sites..."
    sudo ln -s ${virtenv}/${djangProj}/uwsgi.ini /etc/uwsgi/sites/.
fi

################################################################################
echo "Creating nginx config..."
touch ${djangProj}.conf
if [ $thisos != "centos" ]; then
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
    #error_log virtenv/djangProj/data/log/error.log;
    #access_log virtenv/djangProj/data/log/access.log;
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
else
read -d '' uwsgnginx <<"EOF"
#user nginx;
worker_processes auto;
#error_log /var/log/nginx/error.log;
#pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}
http {
     log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    #include /etc/nginx/conf.d/*.conf;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        #root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        #include /etc/nginx/default.d/*.conf;
        location = favicon.ico { access_log off; log_not_found off; }

        location /static/ {
            root virtenv/djangProj;
        }

        location / {
            include virtenv/djangProj/uwsgi_params;
            uwsgi_pass unix:/run/uwsgi/djangProj.sock;
        }
    }
}
EOF
fi
echo "$uwsgnginx" >> ${djangProj}.conf
echo "Modifying nginx config..."
sed -i s/virtenv/${virtenv0}/g ${djangProj}.conf
sed -i s/djangProj/${djangProj}/g ${djangProj}.conf
if [ $thisos = "centos" ]; then
    #echo "Linking config to conf.d..."
    #sudo ln -s ${virtenv}/${djangProj}/${djangProj}.conf /etc/nginx/conf.d/.
    echo "Overwriting nginx.conf..."
    sudo cp -fv ${virtenv}/${djangProj}/${djangProj}.conf /etc/nginx/nginx.conf
else
    echo "Linking config to sites-enabled..."
    sudo ln -s ${virtenv}/${djangProj}/${djangProj}.conf /etc/nginx/sites-enabled/.
    echo "Removing nginx default site..."
    sudo rm -f /etc/nginx/sites-enabled/default
fi

if [ $thisos = "centos" ]; then
    echo "Setting permissions for nginx..."
    sudo usermod -a -G ${USER} nginx
    sudo chmod 710 ${virtenv}/${djangProj}
fi
################################################################################

echo "Creating uWSGI service with systemd..."
sudo touch /etc/systemd/system/uwsgi.service
sudo chown $USER:$USER /etc/systemd/system/uwsgi.service
sudo touch /var/log/uwsgi.log
if [ $thisos = "centos" ]; then
read -d '' uwsgisvc <<"EOF"
[Unit]
Description=uWSGI Emperor service

[Service]
PIDFile=/run/uwsgi/uwsgi.pid
ExecStartPre=/usr/bin/bash -c 'mkdir -p /run/uwsgi; chown thisuser:nginx /run/uwsgi'
ExecStart=virtenv/bin/uwsgi --emperor /etc/uwsgi/sites
Restart=always
KillSignal=SIGQUIT
Type=notify
StandardError=syslog
NotifyAccess=all

[Install]
WantedBy=multi-user.target
EOF
else
read -d '' uwsgisvc <<"EOF"
[Unit]
Description=uWSGI Emperor
After=syslog.target

[Service]
PIDFile=/run/uwsgi/uwsgi.pid
ExecStartPre=/bin/mkdir -p /run/uwsgi
#ExecStartPre=/bin/chown http:http /run/uwsgi
ExecStart=virtenv/bin/uwsgi --ini virtenv/djangProj/uwsgi.ini --enable-threads
RuntimeDirectory=uwsgi
Restart=always
KillSignal=SIGQUIT
Type=notify
StandardError=syslog
NotifyAccess=main

[Install]
WantedBy=multi-user.target
EOF
fi
echo "$uwsgisvc" >> /etc/systemd/system/uwsgi.service
echo "Modifying paths in uwsgi.service..."
sudo sed -i s/thisuser/${USER}/g /etc/systemd/system/uwsgi.service
sudo sed -i s/virtenv/${virtenv0}/g /etc/systemd/system/uwsgi.service
sudo sed -i s/djangProj/${djangProj}/g /etc/systemd/system/uwsgi.service
################################################################################

echo "Checking uwsgi.service for errors..."
sudo chown root:root /etc/systemd/system/uwsgi.service
sudo systemd-analyze verify /etc/systemd/system/uwsgi.service
echo "Starting uwsgi.service..."
sudo systemctl start uwsgi
echo "Restarting nginx service..."
sudo systemctl start nginx
sudo systemctl restart nginx
echo "Setting uwsgi service to auto-start..."
sudo systemctl enable uwsgi.service
sudo systemctl enable nginx
################################################################################

echo "Creating ${mgmtdir} for Django helper scripts..."
sudo mkdir -p ${mgmtdir}
sudo chown -R ${USER}:${USER} ${mgmtdir}
echo "Copying scripts in ${installerdir}/django-mgmt to ${mgmtdir} ..."
cp -v ${installerdir}/django-mgmt/*.sh ${mgmtdir}/.

echo "Saving Django site settings to django_settings.sh ..."
cd ${mgmtdir}
settingsfile=${mgmtdir}/django_settings.sh
# touch ${settingsfile}
# read -d '' djangsettings <<"EOF"
# #!/bin/bash
# # This settings file defines how Django was set up
# # You can reference this script by using:
# #  source django_settings.sh

# EOF
# echo "$djangsettings" >> ${settingsfile}
# echo "virtenv=${virtenv}" >> ${settingsfile}
echo "project=${djangProj}" >> ${settingsfile}

echo "Setting management scripts to executible..."
chmod +x *.sh
