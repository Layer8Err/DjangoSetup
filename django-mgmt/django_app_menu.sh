#!/bin/bash
HEIGHT=12
WIDTH=40
CHOICE_HEIGHT=4
BACKTITLE="Django App Menu"
TITLE="Django Application Options"
MENU="Choose one of the following:"
ALOOP=1

source django_settings.sh

function pause {
	read -n1 -r -p "Press any key to continue..." key
}

function vdjangEnv {
	cd ${virtenv}
	source bin/activate
	cd ${virtenv}/${project}
}

OPTIONS=(1 "Create Django app"
	2 "Import Django app"
	3 "Package Django app"
	4 "Exit Django App Menu")
	
while [ 1 == $ALOOP ] ; do
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
			echo "Creating Django app..."
			./createapp.sh
			pause
			;;
		2)
			echo "Import Django app..."
			./importapp.sh
			pause
			;;
		3)
			echo "Packaging Django app..."
			./packageapp.sh
			pause
			;;
		4)
			echo ""
			ALOOP=2
			;;
	esac
done
