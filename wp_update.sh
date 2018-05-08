#!/bin/sh

#  wp_update.sh
#  
#
#  Created by Marc Palmer on 8/16/16.
#

# Define Variables
WEB_ROOT=$1
SUBFOLDER=$2
WEB_ROOT_PREFIX=$3

WP_UPDATE_LOGS=/var/log/wp-update.log

# Capture Errors
function OwnError() {
    echo "[ `date` ] $(tput setaf 1)$@$(tput sgr0)" | tee -ai $WP_UPDATE_LOGS
    exit $2
}

function WP_UPDATE() {

    # Check WP-CLI is installed or not
    wp --allow-root --info 2> /dev/null
    if [ $? -ne 0 ]; then
        echo "Downloading WP-CLI, Please wait..."
        wget -qO /usr/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        || OwnError "Unable to download WP-CLI, exit status = " $?

        # Executable permission
        chmod a+x /usr/bin/wp || OwnError "Unable to set executable permission for wp-cli, exit status = " $?
    fi

    # Update WP-CLI to prevent any sort of issues that can be caused by old code and a new version of WordPress
    wp cli update

    # Check For WordPress
    for i in $(ls $WEB_ROOT/$SUBFOLDER);do
        if [ -d "$WEB_ROOT/$SUBFOLDER/$i/$WEB_ROOT_PREFIX/wp-admin" ]; then
            echo "Found wp-admin at $WEB_ROOT/$i/$WEB_ROOT_PREFIX/wp-admin"
            cd $WEB_ROOT/$SUBFOLDER/$i/$WEB_ROOT_PREFIX/

            # Check out the master repo to not screw up any branches we are working on
            git checkout master

            # Pull the newest code from master in case someone has already updated the site
            git pull production master

            # Update WordPress
            wp --allow-root core update

            # Update WordPress Plugins
            wp --allow-root plugin update --all

            # Update WordPress Themes
            wp --allow-root theme update --all

            # Add the files to GIT and prepare for commit
            git add .

            # Commit the changes into GIT for manual pushing
            git commit -m "Updated WordPress core, themes, and plugins using the automated script"
        fi
    done
}

# Check and set WEB_ROOT
if [ -z "$WEB_ROOT" ]; then
    read -p "Enter Web Root Path [/var/www]: " WEB_ROOT
    if [[ $WEB_ROOT = "" ]]; then
        WEB_ROOT="/Library/WebServer/Documents"
    fi
fi

if [ -z "$SUBFOLDER" ]; then
	read -p "Enter the subfolder to update [stlclients, 2060digital, etc.]: " SUBFOLDER
	if [[ $SUBFOLDER = "" ]]; then
		SUBFOLDER = "stlclients"
	fi
fi

# Check and set WEB_ROOT_PREFIX
if [ -z "$WEB_ROOT_PREFIX" ]; then
    read -p "Enter Web Root Path [htdocs]: " WEB_ROOT_PREFIX
        if [[ $WEB_ROOT_PREFIX = "" ]]; then
        WEB_ROOT_PREFIX="public_html"
    fi
fi

echo "WEB_ROOT = $WEB_ROOT" | tee -ai $WP_UPDATE_LOGS
echo "WEB_ROOT_PREFIX = $WEB_ROOT_PREFIX" | tee -ai $WP_UPDATE_LOGS

WP_UPDATE | tee -ai $WP_UPDATE_LOGS
