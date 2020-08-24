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
RESOURCES="${PATH_SCRIPT%/*}/../resources"

# Common tools
apt-get install -y htop iftop iotop nmap tig unzip

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
    #ServerName www.refjugeeks.net

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

mkdir -p "$GRAV_WEBROOT"
chown -R "$GRAV_USER":"$GRAV_GROUP" "$GRAV_WEBROOT"

# sv_downloadurl setup (redirects webroot to /mnt/... (expects e.g. external storage)
SVDURL_CONFIG="refjugeeks-svdurl"
SVDURL_WEBROOT="/home/www/svdurl"
SVDURL_STORAGE="/mnt/srv/svdurl"
SVDURL_USER="www-data"
SVDURL_GROUP="$SVDURL_USER"

cat >> "/etc/apache2/sites-available/${SVDURL_CONFIG}.conf" << EOF
<VirtualHost *:80>
    ServerName svdurl.refjugeeks.net

    ServerAdmin webmaster@localhost
    DocumentRoot /home/www/svdurl

    <Directory /home/www/svdurl>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

EOF

mkdir -p "$SVDURL_STORAGE"
chown -R "$SVDURL_USER":"$SVDURL_GROUP" "$SVDURL_STORAGE"
ln -s "$SVDURL_STORAGE" "$SVDURL_WEBROOT"
chown -h "$SVDURL_USER":"$SVDURL_GROUP" "$SVDURL_WEBROOT"

# Apache config
a2enmod rewrite
a2dissite 000-default
a2ensite "$GRAV_CONFIG"
a2ensite "$SVDURL_CONFIG"

systemctl enable apache2
systemctl restart apache2

# DNS/DHCP
DNSMASQ_DEFAULTS="/etc/default/dnsmasq"
DNSMASQ_CONFIG_D="/etc/dnsmasq.d"

apt-get install -y dnsmasq

sed -i /CONFIG_DIR/s/$/,.select/ "$DNSMASQ_DEFAULTS"
cp -f "$RESOURCES/${DNSMASQ_CONFIG_D##*/}"/*.select "$DNSMASQ_CONFIG_D"
chown 0:0 "$DNSMASQ_CONFIG_D"/*.select
(cd "$DNSMASQ_CONFIG_D" && ln -sf refjugeeks-lan.conf.primary.select refjugeeks-lan.conf)

cp -f "$RESOURCES/dhcp-proxyconfig"/* "$GRAV_WEBROOT"
chown -R "$GRAV_USER":"$GRAV_GROUP" "$GRAV_WEBROOT/"{refjugeeks.pac,wpad.dat}

systemctl enable dnsmasq
systemctl restart dnsmasq

# FTP
apt-get install -y vsftpd ftp

VSFTPD_CONFIG="/etc/vsftpd.conf"
VSFTPD_CONFIG_D="/etc/vsftpd.d"
VSFTPD_USERLIST="$VSFTPD_CONFIG_D/userlist"
VSFTPD_USER="rgeekftp"
VSFTPD_USER_HOME="/mnt/srv/ftp"

mkdir -p "$VSFTPD_CONFIG_D"

if ! grep -q "$VSFTPD_USER" "$VSFTPD_USERLIST" &> /dev/null
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
write_enable=YES

EOF
fi

mkdir -p "$VSFTPD_USER_HOME"
useradd -d "$VSFTPD_USER_HOME" -G ftp -M "$VSFTPD_USER" -s /bin/bash
chown -R "$VSFTPD_USER": "$VSFTPD_USER_HOME"
chmod o-rwx "$VSFTPD_USER_HOME"

echo -n "Type password for user '$VSFTPD_USER': "
read -r -s vsftpd_user_password
echo
echo "$VSFTPD_USER:$vsftpd_user_password" | chpasswd

systemctl enable vsftpd
systemctl restart vsftpd

# HTTP-Proxy
apt-get install -y squid

SQUID_CONFIG="/etc/squid/squid.conf"

if ! grep -q "refjugeeks welcome" "$SQUID_CONFIG"
then
    cat >> "$SQUID_CONFIG" << EOF

# Custom configuration for refjugeeks welcome
acl localnet src 192.168.0.0/24
http_access allow localnet
cache_dir ufs /var/spool/squid 1000 16 256

EOF
fi

systemctl enable squid
systemctl restart squid

