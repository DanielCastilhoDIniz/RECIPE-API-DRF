ARG PYTHON_VERSION=3.11.3
FROM python:${PYTHON_VERSION}-alpine3.18

LABEL maintainer="danielcastilho.com" version="1.0" description="API RECIPE"

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Copia os arquivos de dependências e código-fonte para o contêiner
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
COPY ./scripts /scripts
COPY ./app /app

# Define o diretório de trabalho
WORKDIR /app

# Expõe a porta 8000 para acesso externo
EXPOSE 8000

# Define variáveis de ambiente
ARG DEV=false

# Instala as dependências do projeto
# Instala as dependências do sistema
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client jpeg-dev && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev zlib zlib-dev linux-headers && \
    /py/bin/pip install --no-cache-dir -r /tmp/requirements.txt && \
    if [ "$DEV" = "true" ]; then \
        /py/bin/pip install --no-cache-dir -r /tmp/requirements.dev.txt; \
    fi && \
    apk del .tmp-build-deps && \
    rm -rf /tmp

# Criação de usuário sem privilégios e permissões corretas
RUN adduser --disabled-password --no-create-home django-user && \
    mkdir -p /vol/web/media && \
    mkdir -p /vol/web/static && \
    chown -R django-user:django-user /app /vol && \
    chmod -R 755 /vol && \
    chmod -R +x /scripts

# Define variáveis de ambiente
ENV PATH="/scripts:/py/bin:$PATH"


USER django-user

# Executa o script de inicialização do contêiner
CMD ["/scripts/commands.sh"]

# Adiciona um HEALTHCHECK opcional
HEALTHCHECK --interval=60s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1