#!/usr/bin/env bash

echo "++++++++++++++++++ HELLO, DB = $POSTGRES_DB"

echo '++++++++++++++++++ CHECKING HOUSE FILES'
if [ -f $PATH_TO_DBF_FILES/HOUSE01.DBF ]; then
   mv $PATH_TO_DBF_FILES/HOUSE01.DBF $PATH_TO_DBF_FILES/HOUSE.DBF
   echo '++++++++++++++++++ HOUSE INITIAL FILE MOVED'
fi
pgdbf $PATH_TO_DBF_FILES/HOUSE.DBF | iconv -f cp866 -t utf-8 | psql postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB
echo '++++++++++++++++++ INITIAL HOUSE TABLE CREATED'


for FULLPATH in `find $PATH_TO_DBF_FILES/HOUSE* -type f`
do
    FILE="${FULLPATH##*/}"
    TABLE="${FILE%.*}"

    if [ $TABLE = 'HOUSE' ]; then
      echo 'SKIPPING HOUSE'
    else
      pgdbf $FULLPATH | iconv -f cp866 -t utf-8 | psql postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB
      echo "++++++++++++++++++ TABLE $TABLE CREATED"

      echo "++++++++++++++++++ INSERT $TABLE DATA INTO HOUSE"
      psql postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB -c "INSERT INTO house SELECT * FROM $TABLE; DROP TABLE $TABLE;"
    fi

done
