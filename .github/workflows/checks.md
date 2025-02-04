---
name: CI/CD Pipeline

on:
  push:
    branches:
      - develop
  pull_request:
    branches:
      - develop

env:
  DOCKER_IMAGE: ${{ secrets.DOCKERHUB_USER }}/recipe:latest

jobs:
  setup-build:
    name: Setup and Build
    runs-on: ubuntu-latest
    steps:
      # Checkout o código do repositório
      - name: Checkout code
        uses: actions/checkout@v4

      # Login no Docker Hub
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USER }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      # Add support for more platforms with QEMU (optional)
      # https://github.com/docker/setup-qemu-action
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      # Configuração do Docker Buildx
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      # Cache das camadas Docker
      - name: Cache Docker layers
        uses: actions/cache@v3
        with:
          path: /tmp/.buildx-cache
          key: ${{ runner.os }}-buildx-${{ github.sha }}
          restore-keys: |
            ${{ runner.os }}-buildx-

      # Build da imagem Docker
      - name: Build Docker image
        uses: docker/build-push-action@v6

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: setup-build
    services:
      postgres:
        image: postgres:13-alpine
        env:
          DATABASE_NAME: ${{ secrets.DATABASE_NAME }}
          DATABASE_USER: ${{ secrets.DATABASE_USER }}
          DATABASE_PASSWORD: ${{ secrets.DATABASE_PASSWORD }}
          SECRET_KEY: ${{ secrets.SECRET_KEY }}
          DB_ENGINE: ${{ secrets.DB_ENGINE }}
        ports:
          - 5432:5432
    steps:
      # Checkout o código do repositório
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Check or Create .env file
        run: |
          if [ ! -f dotenv_files/.env ]; then
            echo "DATABASE_NAME=${{ secrets.DATABASE_NAME }}" > dotenv_files/.env
            echo "DATABASE_USER=${{ secrets.DATABASE_USER }}" >> dotenv_files/.env
            echo "DATABASE_PASSWORD=${{ secrets.DATABASE_PASSWORD }}" >> dotenv_files/.env
            echo "SECRET_KEY=${{ secrets.SECRET_KEY }}" >> dotenv_files/.env
            echo "DB_ENGINE=${{ secrets.DB_ENGINE }}" >> dotenv_files/.env
          else
            echo ".env file found, skipping creation."
          fi

      # Rodar testes dentro do Docker
      - name: Run tests
        run: |
          docker compose run --rm sgeapp sh -c "
            DATABASE_NAME=${{ secrets.DATABASE_NAME }} \
            DATABASE_USER=${{ secrets.DATABASE_USER }} \
            DATABASE_PASSWORD=${{ secrets.DATABASE_PASSWORD }} \
            SECRET_KEY=${{ secrets.SECRET_KEY }} \
            DB_ENGINE=${{ secrets.DB_ENGINE }} \
            python manage.py wait_for_db &&
            python manage.py test
          "

  lint:
    name: Lint Code
    runs-on: ubuntu-latest
    needs: setup-build
    steps:
      # Checkout o código do repositório
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Check or Create .env file
        run: |
          if [ ! -f dotenv_files/.env ]; then
            echo "DATABASE_NAME=${{ secrets.DATABASE_NAME }}" > dotenv_files/.env
            echo "DATABASE_USER=${{ secrets.DATABASE_USER }}" >> dotenv_files/.env
            echo "DATABASE_PASSWORD=${{ secrets.DATABASE_PASSWORD }}" >> dotenv_files/.env
            echo "SECRET_KEY=${{ secrets.SECRET_KEY }}" >> dotenv_files/.env
            echo "DB_ENGINE=${{ secrets.DB_ENGINE }}" >> dotenv_files/.env
          else
            echo ".env file found, skipping creation."
          fi

       # Análise de código com flake8
      - name: Run flake8
        run: |
          docker compose run --rm sgeapp sh -c "
            DATABASE_NAME=${{ secrets.DATABASE_NAME }} \
            DATABASE_USER=${{ secrets.DATABASE_USER }} \
            DATABASE_PASSWORD=${{ secrets.DATABASE_PASSWORD }} \
            SECRET_KEY=${{ secrets.SECRET_KEY }} \
            DB_ENGINE=${{ secrets.DB_ENGINE }} \
            flake8
              "
      - name: Cleanup .env file
        run: rm dotenv_files/.env

  deploy:
    name: Deploy to Docker Hub
    runs-on: ubuntu-latest
    needs: [setup-build, test, lint]
    steps:
      # Checkout o código do repositório
      - name: Checkout code
        uses: actions/checkout@v4

      # Login no Docker Hub
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USER }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      # Push da imagem para o Docker Hub
      - name: Push Docker image
        run: |
          docker push $DOCKER_IMAGE

okok