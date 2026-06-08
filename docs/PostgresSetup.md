# PostgreSQL Setup

## Prerequisites

- Docker & Docker Compose (recommended for local dev)
- OR a running PostgreSQL 16 instance

## Option 1: Docker Compose (Local Dev)

```bash
cd /path/to/akse

# Start Postgres
docker compose up -d postgres

# Run schema migrations + seed DnD data
cd scripts
npm install
npx tsx db-init.ts
cd ..

# Verify
docker compose exec -T postgres psql -U dnd_admin -d dnd_campaigns -c "\dt"
docker compose exec -T postgres psql -U dnd_admin -d dnd_campaigns -c \
  "SELECT data_type, item_count FROM dnd_data_status ORDER BY data_type;"
```

### Re-seed (optional)

```bash
cd scripts
npx tsx db-init.ts --force
```

## Option 2: Existing PostgreSQL Instance

```bash
# Set environment variables matching your Postgres instance
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_DB=dnd_campaigns
export POSTGRES_USER=dnd_admin
export POSTGRES_PASSWORD=your_password

# Run migrations manually (order matters)
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB \
  -f infrastructure/db/01-init-schema.sql
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB \
  -f infrastructure/db/02-dnd-data-schema.sql
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB \
  -f infrastructure/db/04-notes-schema.sql
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB \
  -f infrastructure/db/05-campaign-emoji.sql

# Seed DnD data
cd scripts
npm install
npx tsx db-init.ts
```

## Option 3: K8s (already running on cluster)

Apply the Postgres StatefulSet from the app-stack, then exec into the pod to run migrations:

```bash
kubectl exec -it postgres-0 -n dnd-app -- psql -U dnd_admin -d dnd_campaigns \
  -c "\dt"

# Run individual migrations
cat infrastructure/db/05-campaign-emoji.sql | \
  kubectl exec -i postgres-0 -n dnd-app -- psql -U dnd_admin -d dnd_campaigns
```

## Default Credentials (local dev)

| Variable | Default |
|----------|---------|
| Host | `localhost` |
| Port | `5432` |
| Database | `dnd_campaigns` |
| User | `dnd_admin` |
| Password | `localdev_secret` |

## Migration Files

All SQL migrations live in `infrastructure/db/` and are executed in alphanumeric order by `db-init.ts`:

| File | Purpose |
|------|---------|
| `01-init-schema.sql` | Users, campaigns, campaign_members, character_sheets, roll_history, initiative_tracker |
| `02-dnd-data-schema.sql` | DnD reference tables (spells, races, classes, etc.) + seeding helpers |
| `03-dev-seed.sql` | Optional dev/test seed data |
| `04-notes-schema.sql` | character_notes table |
| `05-campaign-emoji.sql` | banner_emoji column on campaigns |
