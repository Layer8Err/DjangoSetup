# DjangoSetup
Setup and config Linux server for Django Project

## Django configuration
This script will set up Django to use:
* Nginx as the web server
* uWSGI as the WSGI (utilizing unix socket) in a virtual environment
* Django in a Python3 virtual environment
* PostgreSQL as the database

## Environment
This script has been tested on:
* Ubuntu 16.04 LTS (Server)
* Debian 9 (stretch)
* CentOS 7

## Installation
If you already have git installed, you can install the django environment with the following commands:
```
git clone https://github.com/layer8err/djangosetup
cd djangosetup
chmod +x setup.sh
./setup.sh
```

## Usage
You should be able to run the setup script and follow the prompts
to get things set the way you want. You will probably want to tweak
some of the settings and configurations to suit your needs.

This should allow for app development within an environment that
at least somewhat resembles a production server.
