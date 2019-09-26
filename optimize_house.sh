#!/usr/bin/env bash
echo '_______________________НАЧИНАЮ ОБНОВЛЕНИЕ СХЕМЫ__________________'
#psql postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB -f update_schema_house.sql

echo '_______________________НАЧИНАЮ СОЗДАНИЕ ИНДЕКСОВ_________________'
psql postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB -f house_indexes.sql

echo '_______________________ _________ГОТОВО________ _________________'
