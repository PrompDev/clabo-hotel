#!/bin/sh
set -e
sed -i "s/Limit::perMinute(60)/Limit::perMinute(1000)/g" /var/www/html/app/Providers/RouteServiceProvider.php
sed -i "s/Limit::perMinute(5)/Limit::perMinute(1000)/g" /var/www/html/app/Providers/FortifyServiceProvider.php
sed -i "s/throttle:50,1/throttle:1000,1/g" /var/www/html/routes/api.php
sed -i "s/throttle:15,1/throttle:1000,1/g" /var/www/html/routes/web.php
sed -i "s/throttle:30,1/throttle:1000,1/g" /var/www/html/routes/web.php