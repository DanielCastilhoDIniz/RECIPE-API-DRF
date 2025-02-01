#!/bin/sh


echo "Iniciando o processo de espera pelo banco de dados..."
python manage.py wait_for_db

echo "Aplicando migrações..."
python manage.py migrate --noinput

echo "Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

echo "Iniciando o servidor..."
python manage.py runserver 0.0.0.0:8000
