#!/bin/bash
#
# Execute as 'root'

# Common tools
apt-get install -y unzip

# 'sudo' config
apt-get install -y sudo

cat >> /etc/sudoers.d/rgeek << EOF
rgeek ALL=(ALL) ALL
EOF

chmod 440 /etc/sudoers.d/rgeek

# 'Grav' website
GRAV_WEBROOT="/home/www/html"
GRAV_USER="www-data"
GRAV_GROUP="$GRAV_GROUP"

apt-get install -y apache2 php php-gd php-curl php-xml php-mbstring php-json php-zip php-yaml php-apcu

cat >> /etc/apache2/sites-available/refjugeeks-grav.conf << EOF
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	DocumentRoot $GRAV_WEBROOT

        <Directory /home/www/html>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

EOF

a2enmod rewrite
a2dissite 000-default
a2ensite refjugeeks-grav

systemctl restart apache2

mkdir -p "$GRAV_WEBROOT"
chown -R "$GRAV_USER":"$GRAV_GROUP" "$GRAV_WEBROOT"

# DNS/DHCP
apt-get install -y dnsmasq

# FTP (server)
apt-get install -y ???
