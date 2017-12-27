#!/bin/bash
AHEIGHT=12
AWIDTH=40
ACHOICE_HEIGHT=4
ABACKTITLE="Django App Menu"
ATITLE="Django Application Options"
AMENU="Choose one of the following:"
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

AOPTIONS=(1 "Create Django app"
	2 "Import Django app"
	3 "Package Django app"
	4 "Exit Django App Menu")
	
while [ 1 == $ALOOP ] ; do
	ACHOICE=$(whiptail --clear \
			--backtitle "$ABACKTITLE" \
			--title "$ATITLE" \
			--menu "$AMENU" \
			--ok-button "Launch" \
			--nocancel \
			$AHEIGHT $AWIDTH $ACHOICE_HEIGHT \
			"${AOPTIONS[@]}" \
			2>&1 >/dev/tty)

	clear
	case $ACHOICE in
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
			ALOOP=2
			;;
	esac
done
