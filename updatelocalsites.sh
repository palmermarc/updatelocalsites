#!/bin/bash

for f in /Library/WebServer/Documents/*/; do
        if [ -d ${f} ]; then
                echo $f;
                cd $f/public_html;
                wp core update;
                wp plugin update --all;
                wp theme update --all;
                git add .
                git commit -m "Ran a full update of core, themes, and plugins for WordPress";
        fi
done
