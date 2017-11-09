#!/bin/bash
HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=8
BACKTITLE="Ubuntu Development Server"
TITLE="Django Testing Options"
MENU="Choose one of the following:"
LOOP=1

function pause {
	read -n1 -r -p "Press any key to continue..." key
}

function vdjangEnv {
	cd /opt/project
	source /opt/project/bin/activate
	cd /opt/project/djangSchedule
}

OPTIONS=(1 "Check code"
	2 "Start web server"
	3 "Deploy static files"
	4 "Migrate models.py to database"
	5 "Create models.py from database"
	6 "Start django shell"
	7 "Run django TestCases"
	8 "Exit Django Menu")
	
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
			python3 /opt/project/djangSchedule/manage.py check
			pause
			;;
		2)
			echo "Starting uwsgi \"web server\"..."
			echo "Hit \"Ctrl + C\" to close server"
			cd /opt/project/djangSchedule
			uwsgi --ini /opt/project/djangSchedule/djangSchedule_uwsgi.ini
			pause
			;;
		3)
			echo "Deploying static files..."
			vdjangEnv
			python3 /opt/project/djangSchedule/manage.py collectstatic
			sleep 1
			pause
			;;
		4)
			echo "Migrating models.py to database..."
			sleep 1
			vdjangEnv
			echo "Making migrations..."
			python3 /opt/project/djangSchedule/manage.py makemigrations
			echo "Migrating to database..."
			python3 /opt/project/djangSchedule/manage.py migrate
			sleep 1
			pause
			;;
		5)
			echo "Creating models.py from database..."
			sleep 1
			vdjangEnv
			python3 /opt/project/djangSchedule/manage.py inspectdb
			sleep 1
			pause
			;;
		6)
			echo "Dropping to django shell..."
			sleep 1
			vdjangEnv
			python3 /opt/project/djangSchedule/manage.py shell
			sleep 1
			pause
			;;
		7)
			echo "Running Django TestCases..."
			sleep 1
			vdjangEnv
			python3 /opt/project/djangSchedule/manage.py test schedule
			pause
			;;
		8)
			echo ""
			LOOP=2
			deactivate
			;;
	esac
done
