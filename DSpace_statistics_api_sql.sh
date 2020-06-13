#!/bin/bash
DATABASE_EXISTS=$(echo "SELECT 'CREATE DATABASE $DATABASE_NAME' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DATABASE_NAME')\gexec" | psql -h "$DATABASE_HOST" -U postgres)

if [ "$DATABASE_EXISTS" == "CREATE DATABASE" ]; then
  psql -h "$DATABASE_HOST" -U postgres -c "CREATE USER $DATABASE_USER WITH ENCRYPTED password '$DATABASE_PASS';" >>"$DSPACE_HOME"/log/cron_tab_logs.log 2>&1
  psql -h "$DATABASE_HOST" -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $DATABASE_USER;" >>"$DSPACE_HOME"/log/cron_tab_logs.log 2>&1
else
  echo "DSpace statistics API database exists."
fi
