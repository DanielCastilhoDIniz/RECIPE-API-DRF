#!/bin/sh
set -e  # Faz o script parar em caso de erro

echo "Iniciando o processo de espera pelo banco de dados..."
python manage.py wait_for_db