# Habbo Hotel Private Server — Complete Setup Guide

Complete setup guide for running a Habbo Hotel private server using Arcturus Morningstar 4.0, Nitro React client, and AtomCMS via Docker Compose.

> **Fork of [thebalaa/clabo-hotel](https://github.com/thebalaa/clabo-hotel)** with fixes for PHP 8.4, CSRF errors, missing catalog icons, external access, rate limiting, and Windows localhost deployment.

---

## Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start (Localhost)](#quick-start-localhost)
- [External Access (Port Forwarding)](#external-access-port-forwarding)
- [Fixing Missing Catalog Icons](#fixing-missing-catalog-icons)
- [Admin Commands](#admin-commands)
- [Database Access](#database-access)
- [Known Issues & Fixes](#known-issues--fixes)
- [Troubleshooting](#troubleshooting)
- [Configuration Reference](#configuration-reference)
- [Codex Prompts](#codex-prompts)

---

## Architecture

```
┌─────────────────┐
│   AtomCMS       │  Port 8081 (PHP/Laravel)
│   Login & SSO   │  Generates authentication tokens
└────────┬────────┘
         │ SSO Token
         ▼
┌─────────────────┐
│  Nitro Client   │  Port 3000 (React/TypeScript)
│  Frontend UI    │  Served via nginx
└────────┬────────┘
         │ WebSocket (ws://<YOUR_IP>:2096)
         ▼
┌─────────────────┐
│   Arcturus MS4  │  Port 2096 (WebSocket)
│   Game Server   │  Java emulator
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  MySQL Database │  Port 3310 (mapped from 3306)
│   Data Storage  │
└─────────────────┘
```

**Containers:** db, backup, assets, imager, imgproxy, arcturus, nitro, cms (8 total)

**Ports:**
| Port | Service | Description |
|------|---------|-------------|
| 8081 | CMS | AtomCMS website & login |
| 3000 | Nitro | Game client (React) |
| 2096 | Arcturus | WebSocket game server |
| 8080 | Assets | Furniture, clothing, images |
| 3310 | MySQL | Database (mapped from 3306) |

---

## Prerequisites

- **Docker Desktop** — [download here](https://www.docker.com/products/docker-desktop/)
- **Git** — [download here](https://git-scm.com/)
- **Node.js 15+** — needed for habbo-downloader
- **~10GB free disk space** for assets
- **Ports available:** 2096, 3000, 3310, 8080, 8081

---

## Quick Start (Localhost)

### 1. Clone and Configure

```bash
git clone https://github.com/PrompDev/clappo.git
cd clappo

# Copy example configs
cp example-.env .env
cp example-.cms.env .cms.env
```

### 2. Edit `.cms.env`

<!-- REPLACE: Set APP_URL to your access URL -->
```
APP_URL=http://localhost:8081
SESSION_DOMAIN=localhost
SESSION_SECURE_COOKIE=false
NITRO_CLIENT_PATH=http://localhost:3000
APP_LOCALE=en
THEME=dusk
```

### 3. Edit Nitro Config Files

**`nitro/renderer-config.json`** — find and set:
<!-- REPLACE: Change all IP references to match your setup -->
```json
{
  "socket.url": "ws://localhost:2096",
  "asset.url": "http://127.0.0.1:8080/assets",
  "image.library.url": "http://127.0.0.1:8080/swf/c_images/",
  "hof.furni.url": "http://127.0.0.1:8080/swf/dcr/hof_furni/"
}
```

**`nitro/ui-config.json`** — find and set:
```json
{
  "socket.url": "ws://localhost:2096",
  "url.prefix": "http://127.0.0.1:8081"
}
```

### 4. Build and Start

```bash
# Start database first (needs time to initialize)
docker compose up -d db
# Wait for MySQL to be ready
timeout 15

# Start everything else
docker compose up -d

# Verify all 8 containers are running
docker compose ps
```

### 5. Initialize Database

```bash
docker compose exec db mysql -u arcturus_user -parcturus_pw arcturus < arcturus/arcturus_3.0.0-stable_base_database--compact.sql
```

Apply patches from `arcturus/patches/` if present, then permissions:
```bash
docker compose exec db mysql -u arcturus_user -parcturus_pw arcturus < arcturus/perms_groups.sql
```

### 6. Setup AtomCMS

```bash
# Generate APP_KEY
docker compose exec cms php artisan key:generate --show
# Copy the output to .cms.env as APP_KEY=base64:XXXXX

# Run migrations
docker compose exec cms php artisan migrate --seed --force

# Configure website settings
docker compose exec db mysql -u arcturus_user -parcturus_pw arcturus -e "
UPDATE website_settings SET \`value\` = 'http://127.0.0.1:8080/api/imager/?figure=' WHERE \`key\` = 'avatar_imager';
UPDATE website_settings SET \`value\` = 'http://127.0.0.1:8080/swf/c_images/album1584' WHERE \`key\` = 'badges_path';
UPDATE website_settings SET \`value\` = 'http://127.0.0.1:8080/usercontent/badgeparts/generated' WHERE \`key\` = 'group_badge_path';
UPDATE website_settings SET \`value\` = 'http://127.0.0.1:8080/swf/dcr/hof_furni' WHERE \`key\` = 'furniture_icons_path';
UPDATE website_settings SET \`value\` = 'http://127.0.0.1:3000' WHERE \`key\` = 'nitro_path';
"

# Get installation key (save this!)
docker compose exec db mysql -u arcturus_user -parcturus_pw arcturus -e "SELECT installation_key FROM website_installation;"
```

### 7. Create Admin User

```bash
docker compose exec db mysql -u arcturus_user -parcturus_pw arcturus -e "
INSERT INTO users (username, password, mail, account_created, \`rank\`, credits, pixels, points)
VALUES ('admin', 'temp', 'admin@localhost.com', UNIX_TIMESTAMP(), 7, 99999, 99999, 99999);
"

# Generate proper bcrypt password hash
docker compose exec cms php -r "echo password_hash('admin', PASSWORD_BCRYPT);"
# Copy the output hash, then:
docker compose exec db mysql -u arcturus_user -parcturus_pw arcturus -e "
UPDATE users SET password='PASTE_HASH_HERE' WHERE username='admin';
"
```

### 8. Clear Caches and Restart

```bash
docker compose exec cms php artisan cache:clear
docker compose exec cms php artisan config:clear
docker compose exec cms php artisan view:clear
docker compose exec cms php artisan route:clear
docker compose restart cms
```

### 9. Access the Hotel

1. Open `http://localhost:8081`
2. Enter the installation key from step 6
3. Login with `admin` / `admin`
4. Click **"Hotel"** to enter the game

> **Important:** Always access through the CMS (port 8081), never directly via port 3000. The CMS generates SSO tokens needed for authentication.

---

## External Access (Port Forwarding)

To let other people connect to your server from the internet:

### 1. Find Your IPs

<!-- REPLACE: Run these commands to find YOUR actual IPs -->
```bash
# Public IP (visit in browser or run):
curl ifconfig.me

# Local IP (Windows):
ipconfig
# Look for IPv4 Address, e.g. 192.168.1.105
```

### 2. Router Port Forwarding

Log into your router and add these port forwards:

| Service Name | External Port | Internal Port | Internal IP | Protocol |
|---|---|---|---|---|
| Habbo CMS | 8081 | 8081 | <!-- REPLACE: YOUR_LOCAL_IP --> | TCP |
| Habbo WebSocket | 2096 | 2096 | <!-- REPLACE: YOUR_LOCAL_IP --> | TCP |
| Habbo Assets | 8080 | 8080 | <!-- REPLACE: YOUR_LOCAL_IP --> | TCP |
| Habbo Client | 3000 | 3000 | <!-- REPLACE: YOUR_LOCAL_IP --> | TCP |

### 3. Windows Firewall

```powershell
New-NetFirewallRule -DisplayName "Habbo Hotel" -Direction Inbound -Protocol TCP -LocalPort 8081,2096,8080,3000 -Action Allow
```

### 4. Update All Configs

Replace `localhost` and `127.0.0.1` with your **public IP** in:

**`.cms.env`:**
<!-- REPLACE: Use your public IP below -->
```
APP_URL=http://<YOUR_PUBLIC_IP>:8081
SESSION_DOMAIN=<YOUR_PUBLIC_IP>
NITRO_CLIENT_PATH=http://<YOUR_PUBLIC_IP>:3000
```

**`nitro/renderer-config.json`:**
```json
{
  "socket.url": "ws://<YOUR_PUBLIC_IP>:2096",
  "asset.url": "http://<YOUR_PUBLIC_IP>:8080/assets",
  "image.library.url": "http://<YOUR_PUBLIC_IP>:8080/swf/c_images/",
  "hof.furni.url": "http://<YOUR_PUBLIC_IP>:8080/swf/dcr/hof_furni/"
}
```

**`nitro/ui-config.json`:**
```json
{
  "socket.url": "ws://<YOUR_PUBLIC_IP>:2096",
  "url.prefix": "http://<YOUR_PUBLIC_IP>:8081"
}
```

**Database:**
```bash
docker compose exec db mysql -u arcturus_user -parcturus_pw arcturus -e "
UPDATE emulator_settings SET \`value\`='*' WHERE \`key\`='websockets.whitelist';
UPDATE website_settings SET \`value\` = REPLACE(\`value\`, '127.0.0.1', '<YOUR_PUBLIC_IP>') WHERE \`value\` LIKE '%127.0.0.1%';
UPDATE website_settings SET \`value\` = REPLACE(\`value\`, 'localhost', '<YOUR_PUBLIC_IP>') WHERE \`value\` LIKE '%localhost%';
UPDATE emulator_settings SET \`value\` = REPLACE(\`value\`, '127.0.0.1', '<YOUR_PUBLIC_IP>') WHERE \`value\` LIKE '%127.0.0.1%';
UPDATE emulator_settings SET \`value\` = REPLACE(\`value\`, 'localhost', '<YOUR_PUBLIC_IP>') WHERE \`value\` LIKE '%localhost%';
"
```

### 5. Clear Caches and Restart

```bash
docker compose exec cms php artisan cache:clear
docker compose exec cms php artisan config:clear
docker compose exec cms php artisan view:clear
docker compose exec cms php artisan route:clear
docker compose down
docker compose up -d db
timeout 15
docker compose up -d
```

### 6. Cleanup When Done

Remove router port forwards manually, then:
```powershell
Remove-NetFirewallRule -DisplayName "Habbo Hotel"
```

---

## Fixing Missing Catalog Icons

The Shop, Inventory, and Builder catalog show blank thumbnails because furniture **icon PNGs** are separate from `.nitro` bundles.

### What's Missing

| Asset Type | What it is | Status |
|---|---|---|
| Nitro bundles (.nitro) | 3D furniture rendering | ✅ Working |
| Catalog icons (PNG) | Small UI thumbnails | ❌ Missing |

### Fix

```bash
# Install habbo-downloader (requires Node.js 15+)
npm i -g habbo-downloader

# Download icon files
habbo-downloader --output ./assets/swf --domain com --command icons

# Move icons to correct directory (Nitro expects them in root of hof_furni)
cp -n assets/swf/dcr/hof_furni/icons/* assets/swf/dcr/hof_furni/

# Restart assets container
docker compose restart assets
```

Hard refresh the browser (`Ctrl+Shift+R`) to see the icons.

### Verify

Check `renderer-config.json` has:
```json
"hof.furni.url": "http://<YOUR_IP>:8080/swf/dcr/hof_furni/"
```

---

## Admin Commands

Type these in the Habbo chat (requires rank 7):

| Command | Description |
|---|---|
| `:credits <user> <amount>` | Give credits |
| `:duckets <user> <amount>` | Give duckets |
| `:diamonds <user> <amount>` | Give diamonds |
| `:give <user> <item_id> <amount>` | Give furniture |
| `:masscredits <amount>` | Give credits to everyone online |
| `:summon <user>` | Teleport user to you |
| `:kick <user>` | Kick from room |
| `:ban <user>` | Ban user |
| `:freeze <user>` | Freeze user |
| `:enable <effect_id>` | Enable avatar effect |
| `:transform <pet> <color>` | Turn into pet |
| `:moonwalk` | Moonwalk toggle |
| `:fastwalk` | Fast walk toggle |
| `:invisible` | Toggle invisibility |
| `:roommute` | Mute room |
| `:roomalert <msg>` | Alert room |
| `:hotelalert <msg>` | Alert entire hotel |

To see all available commands:
```sql
SELECT command, description, minimum_rank FROM permission_commands ORDER BY minimum_rank, command;
```

---

## Database Access

```bash
# Enter MySQL shell
docker compose exec db mysql -u arcturus_user -parcturus_pw arcturus

# Quick queries (from PowerShell/terminal)
docker compose exec db mysql -u arcturus_user -parcturus_pw arcturus -e "SELECT id, username, \`rank\` FROM users;"
```

### Common Database Tasks

**Give a user admin rank:**
```sql
UPDATE users SET `rank`=7 WHERE username='USERNAME';
```
> Note: `rank` is a reserved word — always use backticks.

**Give credits:**
```sql
UPDATE users SET credits=99999 WHERE username='USERNAME';
```

**Reset a password:**
```bash
# Generate bcrypt hash
docker compose exec cms php -r "echo password_hash('newpassword', PASSWORD_BCRYPT);"
# Then update
docker compose exec db mysql -u arcturus_user -parcturus_pw arcturus -e "UPDATE users SET password='PASTE_HASH' WHERE username='USERNAME';"
```

**Check all users:**
```sql
SELECT id, username, `rank`, ip_register, account_created FROM users ORDER BY id DESC;
```

**Increase registration limit per IP:**
```sql
UPDATE website_settings SET `value` = '100' WHERE `key` LIKE '%max_accounts%';
```

---

## Known Issues & Fixes

### 419 Page Expired (CSRF Error)

**Cause:** Laravel session/CSRF mismatch in Docker.

**Fix:**
```bash
docker compose exec cms chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
docker compose exec cms chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
```
Ensure `.cms.env` has `APP_URL`, `SESSION_DOMAIN`, and `SESSION_SECURE_COOKIE=false` matching your actual access URL.

### 429 Too Many Requests

**Cause:** Laravel rate limiter treats all external users as the same IP behind NAT.

**Fix:** Remove or increase throttle middleware in AtomCMS. Search for `throttle` in:
- `app/Http/Kernel.php`
- `routes/api.php`
- `routes/web.php`
- `app/Providers/RouteServiceProvider.php`

Remove the throttle middleware or increase to 1000+ requests per minute.

### 500 Server Error After Restart

**Cause:** CMS container starts before MySQL is ready.

**Fix:** Always start db first:
```bash
docker compose up -d db
timeout 15
docker compose up -d
```

### PHP 8.5+ Compatibility

**Cause:** Latest PHP too new for AtomCMS dependencies.

**Fix:** Already applied in this fork — `atomcms/Dockerfile` pins PHP to 8.4.

### entrypoint.d CRLF Line Endings (Windows)

**Cause:** Git on Windows converts LF to CRLF, breaking shell scripts.

**Fix:** Convert `atomcms/entrypoint.d/01-fix-permissions.sh` from CRLF to LF using your editor or:
```bash
sed -i 's/\r$//' atomcms/entrypoint.d/01-fix-permissions.sh
```

---

## Troubleshooting

### Check container status
```bash
docker compose ps
```

### View logs
```bash
docker compose logs cms --tail 50
docker compose logs arcturus --tail 50
docker compose logs nitro --tail 50
```

### CMS Laravel error log
```bash
docker compose exec cms cat /var/www/html/storage/logs/laravel.log | tail -100
```

### Full restart
```bash
docker compose down
docker compose up -d db
timeout 15
docker compose up -d
```

### Clear all caches
```bash
docker compose exec cms php artisan cache:clear
docker compose exec cms php artisan config:clear
docker compose exec cms php artisan view:clear
docker compose exec cms php artisan route:clear
```

### Port conflict on 3000
```bash
# Windows: find what's using port 3000
netstat -ano | findstr :3000
# Kill it or stop the other service first
```

---

## Configuration Reference

### Files You Need to Edit

| File | What to change |
|---|---|
| `.env` | Database credentials |
| `.cms.env` | APP_URL, SESSION_DOMAIN, NITRO_CLIENT_PATH, APP_KEY |
| `nitro/renderer-config.json` | socket.url, asset.url, image URLs |
| `nitro/ui-config.json` | socket.url, url.prefix |
| Database `emulator_settings` | websockets.whitelist |
| Database `website_settings` | avatar_imager, nitro_path, badge paths |

### Default Credentials

| What | Value |
|---|---|
| Admin username | admin |
| Admin password | admin |
| Admin rank | 7 (Owner) |
| DB username | arcturus_user |
| DB password | arcturus_pw |
| DB name | arcturus |

---

## Codex Prompts

### Prompt: Initial Setup on Windows Localhost

```
Task: Set up the clabo-hotel Habbo private server on Windows localhost using Docker.

Project location: <YOUR_PROJECT_PATH>

Steps:
1. Copy example-.env to .env and example-.cms.env to .cms.env
2. Pin PHP to 8.4 in atomcms/Dockerfile if not already done
3. Convert atomcms/entrypoint.d/01-fix-permissions.sh from CRLF to LF
4. Start containers: docker compose up -d db, wait 15 seconds, docker compose up -d
5. Import base database, patches, and permissions SQL
6. Generate APP_KEY and update .cms.env
7. Run migrations: docker compose exec cms php artisan migrate --seed --force
8. Configure website_settings in database
9. Create admin user with bcrypt password hash
10. Clear all Laravel caches and restart cms
11. Verify at http://localhost:8081
```

### Prompt: Switch to External Access

```
Task: Replace all localhost/127.0.0.1 references with my public IP so external users can connect.

Steps:
1. Run "curl ifconfig.me" to get public IP
2. Run "ipconfig" to get local IP for port forwarding
3. Create Windows firewall rule for ports 8081,2096,8080,3000
4. Update .cms.env with public IP (APP_URL, SESSION_DOMAIN, NITRO_CLIENT_PATH)
5. Update nitro/renderer-config.json with public IP
6. Update nitro/ui-config.json with public IP
7. Update database emulator_settings and website_settings with public IP
8. Set websockets.whitelist to '*'
9. Clear caches and restart all containers
10. Verify no localhost/127.0.0.1 remains: grep -r "localhost\|127\.0\.0\.1" nitro/ .cms.env
```

### Prompt: Fix Missing Catalog Icons

```
Task: Download and install furniture icon PNGs for the Habbo catalog/inventory.

Steps:
1. Install habbo-downloader: npm i -g habbo-downloader
2. Download icons: habbo-downloader --output ./assets/swf --domain com --command icons
3. Copy icons to correct path: cp -n assets/swf/dcr/hof_furni/icons/* assets/swf/dcr/hof_furni/
4. Restart assets container: docker compose restart assets
5. Verify hof.furni.url in renderer-config.json points to correct path
```

### Prompt: Discover Your Network Info and Update This Document

```
Task: Find my public IP and local IP, then update SETUP.md with the correct values.

Steps:
1. Run "curl ifconfig.me" to get public IP
2. Run "ipconfig" to get local network IP (IPv4 Address under your active adapter)
3. In SETUP.md, replace all instances of <YOUR_PUBLIC_IP> with your actual public IP
4. In SETUP.md, replace all instances of <YOUR_LOCAL_IP> with your actual local IP
5. In SETUP.md, replace <YOUR_PROJECT_PATH> with the actual path to your project folder
6. Save the file
```

---

## License

This setup uses multiple open-source projects, each with their own licenses. Refer to individual project repositories for license details.

- **Arcturus Morningstar:** https://git.krews.org/morningstar/Arcturus-Community
- **Nitro Client:** https://github.com/billsonnn/nitro-react
- **AtomCMS:** https://github.com/atom-retros/atomcms
- **Original clabo-hotel:** https://github.com/thebalaa/clabo-hotel
