#!/bin/bash
# This settings file defines how Django was set up
# You can reference this script by using:
#  source django_settings.sh
djangoMgmtDir="$(dirname "$(readlink -f "$0")")"
virtDir="$(dirname "$djangoMgmtDir")" # This should be the virtenv path
virtenv="$virtDir"
