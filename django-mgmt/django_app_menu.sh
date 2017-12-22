#!/bin/bash
HEIGHT=12
WIDTH=40
CHOICE_HEIGHT=4
BACKTITLE="Django App Menu"
TITLE="Django Application Options"
MENU="Choose one of the following:"
LOOP=1

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
			echo "Creating Django app..."
			source createapp.sh
			pause
			;;
		2)
			echo "Import Django app..."
			source importapp.sh
			pause
			;;
		3)
			echo "Packaging Django app..."
			source packageapp.sh
			pause
			;;
		4)
			echo ""
			LOOP=2
			deactivate
			;;
	esac
done
