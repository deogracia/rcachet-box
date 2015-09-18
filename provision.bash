#!/usr/bin/env bash

####
#
# variables
#
####

export DEBIAN_FRONTEND=noninteractive

source /vagrant/provisionning/common/log.bash

####
#
# Début exécution
#
####


logAndPrint "Debut provisionning..."

echo "logfile : $LogFile"

logAndPrint "###"
logAndPrint "###"
logAndPrint "###"
logAndPrint "01. on fait le ménage et on met à  jour notre systeme."

apt-get clean all       2>&1 | tee -a $LogFile
apt-get update          2>&1 | tee -a $LogFile
apt-get dist-upgrade -y 2>&1 | tee -a $LogFile


logAndPrint "###"
logAndPrint "###"
logAndPrint "###"
logAndPrint "02. on install les dépendances."

logAndPrint "###"
logAndPrint "02.01 On installe PHP & apache."
apt-get install -y php5-cli php5-apcu php5-intl php5-mysql 2>&1 | tee -a $LogFile
apt-get install -y apache2 apache2-mpm-itk libapache2-mod-php5 2>&1 | tee -a $LogFile
/bin/cp /vagrant/files/cachet.conf-vagrant /etc/apache2/sites-available/cachet.conf 2>&1 | tee -a $LogFile
/usr/sbin/a2ensite cachet 2>&1 | tee -a $LogFile
/bin/rm /etc/apache2/sites-enabled/000-default.conf 2>&1 | tee -a $LogFile
/usr/sbin/a2enmod rewrite 2>&1 | tee -a $LogFile
/usr/sbin/apache2ctl -t 2>&1 | tee -a $LogFile && /usr/sbin/apache2ctl restart 2>&1 | tee -a $LogFile

logAndPrint "###"
logAndPrint "02.02 On installe MySQL."
apt-get install -y mysql-server 2>&1 | tee -a $LogFile

logAndPrint "###"
logAndPrint "02.03 On installe git & a global composer."
apt-get install -y git 2>&1 | tee -a $LogFile

curl -sS https://getcomposer.org/installer | php 2>&1 | tee -a $LogFile
mv composer.phar /usr/local/bin/composer 2>&1 | tee -a $LogFile

logAndPrint "###"
logAndPrint "###"
logAndPrint "###"
logAndPrint "03. On install cachet :D."

logAndPrint "###"
logAndPrint "03.01 On clone le dépôt."
sudo -H -i -u vagrant /bin/bash -c "cd ~ && git clone https://github.com/cachethq/Cachet.git" 2>&1 | tee -a $LogFile
sudo -H -i -u vagrant /bin/bash -c "cd ~/Cachet && git checkout v1.2.1" 2>&1 | tee -a $LogFile

logAndPrint "###"
logAndPrint "03.02 On configure le tout."
sudo -H -i -u vagrant /bin/bash -c "cd ~/Cachet && cp /vagrant/files/env-vagrant .env" 2>&1 | tee -a $LogFile
sudo -H -i -u vagrant /bin/bash -c "cd ~/Cachet && composer install --no-dev -o" 2>&1 | tee -a $LogFile
/usr/bin/mysql -e "create database cachet;" 2>&1 | tee -a $LogFile
sudo -H -i -u vagrant /bin/bash -c "cd ~/Cachet && php artisan migrate --force" 2>&1 | tee -a $LogFile
sudo -H -i -u vagrant /bin/bash -c "cd ~/Cachet && php artisan key:generate" 2>&1 | tee -a $LogFile
sudo -H -i -u vagrant /bin/bash -c "cd ~/Cachet && php artisan config:cache" 2>&1 | tee -a $LogFile

logAndPrint "###"
logAndPrint "03.03 On injecte les données de base."
/usr/bin/mysql cachet < /vagrant/files/basic_settings.sql 2>&1 | tee -a $LogFile
/usr/bin/mysql cachet < /vagrant/files/set_users.sql 2>&1 | tee -a $LogFile
