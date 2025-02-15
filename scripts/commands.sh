#!/bin/sh
set -e  # Faz o script parar em caso de erro

# echo "Iniciando o processo de espera pelo banco de dados..."
# python manage.py wait_for_db

# echo "Aplicando migrações..."
# python manage.py migrate --noinput

# echo "Coletando arquivos estáticos..."
# python manage.py collectstatic --noinput

# Define a porta do servidor a partir da variável de ambiente ou usa 8000 como padrão
# PORT=${PORT:-8000}

# echo "Iniciando o servidor Django na porta $PORT..."
# # exec python manage.py runserver 0.0.0.0:$PORT
