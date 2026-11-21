# Run FurniFlex locally

## Requirements

- Docker Desktop on Windows with Linux containers, or Docker Engine with Compose v2
- Git, if cloning the repository

## First run

1. Clone or download this repository to a new folder. Do not extract it over an existing FurniFlex installation.
2. Copy `.env.example` to `.env` in the repository folder.
3. Set unique values for `DB_PASSWORD` and `DB_ROOT_PASSWORD` in `.env`. Keep this file private; Git ignores it.
4. Open PowerShell in the repository folder and run:

   ```powershell
   docker compose up -d --build
   ```

5. Open <http://localhost:8080>.

The first database volume is initialized from `FurniFlex-Schema.sql`. It creates the application tables without importing users, staff credentials, customer data, catalog records, or transactions. You will need authorized project data to use workflows that depend on catalog entries or staff accounts.

## Daily use

From the repository folder:

```powershell
docker compose start
```

Open <http://localhost:8080>. To stop the application while keeping its data:

```powershell
docker compose stop
```

Do not use `docker compose down --volumes` if you want to keep the database volume. Compose names containers and volumes from the folder name; use a new folder for this checkout to keep it separate from other FurniFlex installations.

## Troubleshooting

- **Docker is unavailable:** Start Docker Desktop, wait until it is ready, and run `docker version`.
- **The app does not open:** Run `docker compose ps` and `docker compose logs --tail 50 app db` from the repository folder.
- **Port 8080 is busy:** Set `APP_PORT=8081` and `APP_BASE_URL=http://localhost:8081` in `.env`, then recreate the app with `docker compose up -d --build`.
- **Database credentials fail:** Do not replace `.env` for an existing database volume. The volume retains the credentials used when MariaDB initialized.
- **Schema changes do not appear:** MariaDB only imports initialization files for a new volume. Existing database data is not reset automatically.

## Data handling

Use fictional data for development. Do not commit `.env`, database backups, uploaded files, logs, reset links, or real customer data. Keep any private project seed and staff credentials in your team's approved private storage.
