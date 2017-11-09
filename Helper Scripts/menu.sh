#!/bin/bash
HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=9
BACKTITLE="Ubuntu Development Server"
TITLE="Program Launcher"
MENU="Choose one of the following:"
LOOP=1

OPTIONS=(1 "Visual Studio Code"
	2 "Geany"
	3 "pgAdmin3"
	4 "FireFox"
	5 "Notepad"
	6 "X Terminal"
	7 "IRC"
	8 "Django testing options"
	9 "Exit to shell")
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
		echo "Launching Visual Studio Code..."
		code
		sleep 1
		;;
	2)
		echo "Launching Geany..."
		geany & disown
		sleep 1
		;;
	3)
		echo "Launching pgAdmin3 (PostgresSQL GUI)..."
		pgadmin3 & disown
		sleep 1
		;;
	4)
		echo "Launching firefox..."
		firefox 127.0.0.1 & disown
		sleep 1
		;;
	5)
		echo "Launching LeafPad..."
		leafpad & disown
		sleep 1
		;;
	6)
		echo "Launching LXTerminal..."
		lxterminal & disown
		sleep 1
 		;;
	7)
		#LOOP=2
		irc -S -c "#dev" 127.0.0.1
		;;
	8)
		bash /opt/scripts/djang_menu.sh
		;;
	9)
		LOOP=2
		;;
esac
done
