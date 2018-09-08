#!/bin/bash
#
# ref'ju:geeks welcome - Debian 9 automatic system setup
#  (primary management host)

if [[ $EUID != 0 ]]
then
    echo "Please run as root" >&2
    exit 128
fi

# Common resources
PATH_SCRIPT="$(realpath "$0")"
RESOURCES="$PATH_SCRIPT/../resources"

# Common tools
apt-get install -y unzip

# sudo and config
apt-get install -y sudo

cat >> /etc/sudoers.d/rgeek << EOF
rgeek ALL=(ALL) ALL
EOF

chmod 440 /etc/sudoers.d/rgeek

# Grav website
GRAV_CONFIG="refjugeeks-grav"
GRAV_WEBROOT="/home/www/html"
GRAV_USER="www-data"
GRAV_GROUP="$GRAV_USER"

apt-get install -y apache2 php php-gd php-curl php-xml php-mbstring php-json php-zip php-yaml php-apcu

cat >> "/etc/apache2/sites-available/${GRAV_CONFIG}.conf" << EOF
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot $GRAV_WEBROOT

        <Directory $GRAV_WEBROOT>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

EOF

a2enmod rewrite
a2dissite 000-default
a2ensite "$GRAV_CONFIG"

systemctl restart apache2

mkdir -p "$GRAV_WEBROOT"
chown -R "$GRAV_USER":"$GRAV_GROUP" "$GRAV_WEBROOT"

# DNS/DHCP
DNSMASQ_DEFAULTS="/etc/default/dnsmasq"
DNSMASQ_CONFIG_D="/etc/dnsmasq.d"

apt-get install -y dnsmasq

sed -i /CONFIG_DIR/ s/$/,.select/ "$DNSMASQ_DEFAULTS"
cp -f "${RESOURCES}${DNSMASQ_CONFIG_D}/*.select" "$DNSMASQ_CONFIG_D"
chown 0:0 "$DNSMASQ_CONFIG_D/*.select"
(cd "$DNSMASQ_CONFIG_D" && ln -sf refjugeeks-lan.conf.primary.select refjugeeks-lan.conf)

systemctl restart dnsmasq

# FTP
apt-get install -y vsftpd ftp

VSFTPD_CONFIG="/etc/vsftpd.conf"
VSFTPD_CONFIG_D="/etc/vsftpd.d"
VSFTPD_USERLIST="$VSFTPD_CONFIG_D/userlist"
VSFTPD_USER="rgeekftp"

mkdir -p "$VSFTPD_CONFIG_D"

if ! grep -q "$VSFTPD_USER" "$VSFTPD_USERLIST"
then
    echo "$VSFTPD_USER" >> "$VSFTPD_USERLIST"
fi

if ! grep -q "refjugeeks welcome" "$VSFTPD_CONFIG"
then
    cat >> "$VSFTPD_CONFIG" << EOF

# Custom configuration for refjugeeks welcome
userlist_file=$VSFTPD_USERLIST
userlist_enable=YES
userlist_deny=NO

EOF
fi

systemctl restart vsftpd

