#!/bin/sh
echo "Criando banco se nao existir..."
PGPASSWORD=$DB_PWD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -tc "SELECT 1 FROM pg_database WHERE datname='bia'" | grep -q 1 || \
  PGPASSWORD=$DB_PWD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "CREATE DATABASE bia"

echo "Rodando migrations..."
./node_modules/.bin/sequelize db:migrate

echo "Iniciando servidor..."
npm start
