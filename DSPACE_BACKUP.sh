#!/bin/bash
db_name="dspace-$(date +%s).dump"

echo "$(tput setaf 6)Creating full backup $db_name.tar.gz ..."$(tput sgr 0)

sudo docker exec -i dspace_db pg_dump -U dspace -Fc -f /var/lib/postgresql/data/$db_name dspace
cd /home/ubuntu/dspace-docker/db_backup/
sudo mv /home/ubuntu/dspace-docker/postgresData/$db_name .
sudo tar -czvf $db_name.tar.gz $db_name
sudo rm /home/ubuntu/db_backup/$db_name
echo "$(tput setaf 6)Backup finished."$(tput sgr 0)

