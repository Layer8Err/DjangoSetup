#!/bin/bash
HEIGHT=14
WIDTH=40
CHOICE_HEIGHT=9
BACKTITLE="Django Menu"
TITLE="Django Testing Options"
MENU="Choose one of the following:"
LOOP=1

source django_settings.sh
#virtenv=/opt/djangvenv
#project=djangsite

function pause {
	read -nexit	
	1 -r -p "Press any key to continue..." key
}

function vdjangEnv {
	cd ${virtenv}
	source bin/activate
	cd ${virtenv}/${project}
 }

OPTIONS=(1 "Check code"
	2 "Start web server"
	3 "Deploy static files"
	4 "Migrate models.py to database"
	5 "Create models.py from database"
	6 "Start django shell"
	7 "Run django TestCases"
	8 "Django App Menu"
	9 "Exit Django Menu")
	
while [ 1 == $LOOP ] ; do
	CHOICE=$(whiptail --clear \
			--backtitle "$BACKTITLE" \
			--title "$TITLE" \
			--menu "$MENU" \
			--ok-button "Launch" \
			--nocancel \
			$HEIGHT $WIDTH $CHOICE_HEIGHT \
			"${OPTIONS[@]}" \
			2>&1 >/dev/tty)

	clear
	case $CHOICE in
		1)
			echo "Checking Django Code..."
			vdjangEnv
			python3 ${virtenv}/${project}/manage.py check
			pause
			;;
		2)
			echo "Starting uwsgi \"web server\"..."
			echo "Hit \"Ctrl + C\" to close server"
			cd ${virtenv}/${project}
			python3 manage.py runserver
			pause
			;;
		3)
			echo "Deploying static files..."
			vdjangEnv
			python3 ${virtenv}/${project}/manage.py collectstatic
			sleep 1
			pause
			;;
		4)
			echo "Migrating models.py to database..."
			sleep 1
			vdjangEnv
			echo "Making migrations..."
			python3 ${virtenv}/${project}/manage.py makemigrations
			echo "Migrating to database..."
			python3 ${virtenv}/${project}/manage.py migrate
			sleep 1
			pause
			;;
		5)
			echo "Creating models.py from database..."
			sleep 1
			vdjangEnv
			python3 ${virtenv}/${project}/manage.py inspectdb
			sleep 1
			pause
			;;
		6)
			echo "Dropping to django shell..."
			sleep 1
			vdjangEnv
			python3 ${virtenv}/${project}/manage.py shell
			sleep 1
			pause
			;;
		7)
			echo "Running Django TestCases..."
			sleep 1
			vdjangEnv
			python3 ${virtenv}/${project}/manage.py test
			pause
			;;
		8)
			echo "Running django_app_menu.sh..."
			sleep 1
			source django_app_menu.sh
			;;
		9)
			echo ""
			LOOP=2
			deactivate
			;;
	esac
done
