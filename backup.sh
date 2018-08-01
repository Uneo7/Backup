#!/bin/bash

## Config ##
source ./swift

release="0.9.1"
repo="/"
driver="swift"
driver_param="Test"
backup_folders="/home/test;/home/test2"

databases="test;test2;test3;test3"

mysql_username="root"
mysql_password=""

export RESTIC_PASSWORD="test"

## End Config ##
command -v restic > /dev/null 2>&1

if [ $? -gt 0 ]; then
        echo "Installing Restic $release"
        wget "https://github.com/restic/restic/releases/download/v$release/restic_${release}_linux_amd64.bz2"
        bzip2 -d restic_${release}_linux_amd64.bz2
        mv ./restic_${release}_linux_amd64 /usr/bin/restic
        chmod +x /usr/bin/restic
        echo "Restic installed"
fi

if [ $driver == "local" ] ; then
        r=$repo
else
        r="$driver:$driver_param:$repo"
fi

restic -r $r snapshots > /dev/null 2>&1

if [ $? -gt 0 ] ; then
        echo "Initializing repo"
        restic -r $r init
fi

folders=(${backup_folders//;/ })

for i in "${folders[@]}" ; do
        echo ""
        echo "$(tput setaf 5)Backuping $(tput sgr 0)$i"

        restic -r $r backup $i
        sleep 2s
done


if [ -n "$databases" ]; then
        d=(${databases//;/ })

        for i in "${d[@]}" ; do
                echo ""
                echo "$(tput setaf 5)Backuping $(tput sgr 0)$i database"

                if [ -n "$mysql_password" ]; then
                        mysqldump -u $mysql_username -p $mysql_password $i | gzip | restic -r $r backup --stdin --stdin-filename $i.sql.gz
                else
                        mysqldump -u $mysql_username $i | gzip | restic -r $r backup --stdin --stdin-filename $i.sql.gz
                fi

                sleep 2s
        done
fi
