#!/bin/bash
db_name="dspace-$(date +%s).dump"

echo "$(tput setaf 6)Creating full backup $db_name.tar.gz ..."$(tput sgr 0)

docker exec -i dspace_db pg_dump -U dspace -Fc -f /$db_name dspace
cd ./db_backup/
docker cp dspace_db:/$db_name .
docker exec dspace_db sh -c "rm /$db_name"
tar -czvf $db_name.tar.gz $db_name
rm $db_name
echo "$(tput setaf 6)Backup finished."$(tput sgr 0)

