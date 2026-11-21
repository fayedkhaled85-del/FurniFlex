# FurniFlex

FurniFlex is a PHP and MariaDB furniture commerce application. Customers can browse and customize catalog furniture or submit made-to-order commissions. Administrators manage the catalog, orders, quotations, and production workflow; manufacturers review and update assigned work.

## Features

- Product catalog, cart, checkout, and order tracking
- Custom furniture requests with quotations and production status
- Browser-based 3D customization using local Three.js models and textures
- Role-aware PHP workflows backed by MariaDB
- Docker Compose setup for local development

Payment and shipping are simulated. The application does not process payments or book carriers.

## Technology

- PHP 8.5, Apache, and PDO
- MariaDB 10.11
- HTML, CSS, and JavaScript
- Three.js with GLB models
- Docker Compose

## Repository contents

- `index.php`, `includes/` — application routes and shared services
- `assets/` — frontend code, vendor libraries, product models, and textures
- `FurniFlex-Schema.sql` — empty database schema used on first initialization
- `database/migrations/` — historical schema and catalog migrations
- `deploy/` — Apache configuration, health check, and environment helper
- `compose.yaml`, `Dockerfile` — local container setup

The delivery database dump is not included. The schema file contains table definitions only: it has no user accounts, password hashes, reset tokens, customer records, orders, or demo transactions. A fresh database therefore has no seeded catalog or staff users. Use approved project data through your team's private process if you need populated records.

## Requirements

- Windows 10/11 with Docker Desktop and Linux containers, or a compatible Docker Engine with Compose v2
- Git (optional, for cloning)

## Run locally

1. Clone or download this repository into a new folder. Do not place it over another FurniFlex installation.
2. Copy `.env.example` to `.env` and set unique values for `DB_PASSWORD` and `DB_ROOT_PASSWORD`.
3. From the repository folder, run:

   ```powershell
   docker compose up -d --build
   ```

4. Open [http://localhost:8080](http://localhost:8080).
5. Stop containers with `docker compose stop`. This keeps the database volume. Do not use `docker compose down --volumes` if you want to retain local database data.

Docker Compose derives its project name from the repository folder. Use a fresh folder for this checkout so its containers and volumes stay separate from other FurniFlex installations.

## Configuration and data

`.env` contains local database passwords and is ignored by Git. Never commit `.env`, database backups, uploaded files, logs, or real user data. The first database initialization imports `FurniFlex-Schema.sql`; MariaDB only imports initialization files when creating a new data volume. Changing the schema file does not modify an existing database volume.



