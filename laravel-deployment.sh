#!/bin/bash

# Author: Jpon9
# ---
# This script deploys a new Laravel installation if one does not exist in the
# given project, otherwise it updates it with code from an archive file

project_name="globaloffensivebot"
archive_path="/home/jake/archive.tar"
creating_new_project=false

cd /var/www/

# If the project exists, require an archive be given, otherwise install Laravel
if [ -r $project_name ] ; then
  if [ ! -r "$archive_path" ] ; then
    echo -e "\e[31mProject $project_name already exists and no archive given, exiting...\e[39m"
    exit -1
  else
    cd $project_name
  fi
else
  # Set creating_new_project to true
  creating_new_project=true

  # If Composer isn't installed, install it globally
  echo -e "\e[32mInstalling composer...\e[39m"
  if [ ! -r /usr/bin/composer ] ; then
    echo -e "\e[33mInstalling Composer globally...\e[39m"
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/bin --filename=composer
  else
    echo -e "\e[32m    ...composer already installed!\e[39m"
  fi

  # Install Laravel
  sudo composer create-project laravel/laravel $project_name --prefer-dist

  # Move into project directory
  cd $project_name

  echo -e "\e[32mInstalling nodejs...\e[39m"
  dpkg-query -l nodejs > /dev/null
  if [ $? -eq 1 ] ; then
    sudo apt-get install -y nodejs
  else
    echo -e "\e[32m    ...nodejs already installed!\e[39m"
  fi


  echo -e "\e[33mInstalling nodejs-legacy...\e[39m"
  dpkg-query -l node > /dev/null
  if [ $? -eq 1 ] ; then
    sudo apt-get install -y nodejs-legacy
  else
    echo -e "\e[32m    ...nodejs-legacy already installed!\e[39m"
  fi

  echo -e "\e[33mInstalling npm...\e[39m"
  dpkg-query -l npm > /dev/null
  if [ $? -eq 1 ] ; then
    sudo apt-get install -y npm
  else
    echo -e "\e[32m    ...npm already installed!\e[39m"
  fi

  # Install the PHP Package Manager "PECL" and its dependencies
  echo -e "\e[33mInstalling php5-dev...\e[39m"
  dpkg-query -l php5-dev > /dev/null
  if [ $? -eq 1 ] ; then
    sudo apt-get install -y php5-dev
  else
    echo -e "\e[32m    ...php5-dev already installed!\e[39m"
  fi

  echo -e "\e[33mInstalling php5-pear...\e[39m"
  which pecl
  if [ $? -eq 1 ] ; then
    sudo apt-get install -y php5-pear
  else
    echo -e "\e[32m    ...php5-pear already installed!\e[39m"
  fi

  # Get the PHP Mongo driver
  echo -e "\e[33mInstalling mongo for PHP...\e[39m"
  pecl list | grep mongo > /dev/null
  if [ $? -eq 1 ] ; then
    sudo pecl install mongo
  else
    echo -e "\e[32m    ...mongo for PHP already installed!\e[39m"
  fi
fi

if [ -r "$archive_path" ] ; then
  # Remove the default composer.lock
  sudo rm -f composer.lock

  # Extract archive with project files
  echo -e "\e[32mUnpacking archive...\e[39m"
  sudo tar xvf "$archive_path"
fi

# Install the necessary project files
sudo composer install
sudo npm install

if [ "$creating_new_project" = true ] ; then
  # Install gulp for compiling LESS
  echo -e "\e[33mInstalling gulp from npm...\e[39m"
  npm list | grep gulp > /dev/null
  if [ $? -eq 1 ] ; then
    sudo npm install gulp
  else
    echo -e "\e[32m    ...gulp already installed!\e[39m"
  fi
fi

# Run gulp to compile the stylesheet
sudo gulp

cd ../

echo -e "\e[32mResetting project permissions...\e[39m"

sudo chown -R jake:jake $project_name/
sudo find $project_name/ -type f -exec chmod 644 {} +
sudo find $project_name/ -type d -exec chmod 755 {} +
sudo chmod -R 777 $project_name/storage $project_name/bootstrap/cache

echo -e "\e[31mIf you have not already,"
echo -e "    - add 'extension=mongo.so' to php.ini, then run 'sudo service apache2 restart'\e[39m"
