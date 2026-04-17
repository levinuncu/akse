# Postgres Setup

```powershell
cd c:\Users\kotfr\Documents\01Studieren\AKSE\akse
```

```powershell
docker compose up -d postgres
```

```powershell
cd scripts
```

```powershell
npm install
```

```powershell
npx tsx db-init.ts
```

```powershell
cd ..
```

```powershell
docker compose exec -T postgres psql -U dnd_admin -d dnd_campaigns -c "\dt"
```

```powershell
docker compose exec -T postgres psql -U dnd_admin -d dnd_campaigns -c "SELECT data_type, item_count FROM dnd_data_status ORDER BY data_type;"
```

## Re-seed (optional)

```powershell
cd scripts
```

```powershell
npx tsx db-init.ts --force
```

## Linux

```bash
cd /path/to/AKSE/akse
```

```bash
docker compose up -d postgres
```

```bash
cd scripts
```

```bash
npm install
```

```bash
npx tsx db-init.ts
```

```bash
cd ..
```

```bash
docker compose exec -T postgres psql -U dnd_admin -d dnd_campaigns -c "\\dt"
```

```bash
docker compose exec -T postgres psql -U dnd_admin -d dnd_campaigns -c "SELECT data_type, item_count FROM dnd_data_status ORDER BY data_type;"
```

### Re-seed (optional)

```bash
cd scripts
```

```bash
npx tsx db-init.ts --force
```
