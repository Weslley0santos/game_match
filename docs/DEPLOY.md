# Deploy local do GameMatch com Docker

Este documento descreve como executar o backend do GameMatch utilizando Docker e Docker Compose.

O ambiente Docker sobe dois serviços principais:

- PostgreSQL: banco de dados da aplicação;
- Backend Spring Boot: API REST do GameMatch.

O frontend Flutter deve ser executado separadamente em ambiente local.

---

## 1. Pré-requisitos

Antes de iniciar, instale:

- Docker;
- Docker Compose;
- Git, caso vá clonar o repositório;
- Flutter SDK, caso vá executar o frontend.

---

## 2. Estrutura esperada

A estrutura principal do projeto deve ser semelhante a:

```txt
game_match/
├── backend/
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
├── frontend/
├── docker-compose.yml
├── .env.example
└── DEPLOY.md