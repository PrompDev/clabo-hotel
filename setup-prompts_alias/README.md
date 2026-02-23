# 🏨 Clappo — Habbo Hotel Private Server (Docker)

A one-command Habbo Hotel private server running Arcturus Morningstar 4.0, Nitro React client, and AtomCMS via Docker Compose.

Fork of [thebalaa/clabo-hotel](https://github.com/thebalaa/clabo-hotel) with fixes for modern deployment.

---

## What's Included

- **Arcturus Morningstar 4.0** — Java game server emulator
- **Nitro Client** — React/TypeScript Habbo client (HTML5, no Flash)
- **AtomCMS** — Laravel CMS with registration, login, SSO, housekeeping
- **MySQL 8** — Database with automatic backups
- **Asset Pipeline** — SWF → Nitro conversion, avatar imager, image proxy

## What's Fixed (vs original repo)

- ✅ PHP pinned to 8.4 (fixes compatibility with latest Alpine images)
- ✅ CRLF → LF fix for Windows Docker builds
- ✅ 419 CSRF error fix (session/cookie configuration)
- ✅ 429 rate limiting fix for NAT/Docker environments
- ✅ Missing catalog/inventory icon fix (habbo-downloader instructions)
- ✅ External access guide (port forwarding + config updates)
- ✅ Complete Windows localhost deployment guide
- ✅ Codex-ready prompts for AI-assisted setup

---

## Quick Start

```bash
git clone https://github.com/PrompDev/clappo.git
cd clappo
cp example-.env .env
cp example-.cms.env .cms.env

docker compose up -d db
timeout 15
docker compose up -d
```

Then follow the full guide in **[SETUP.md](SETUP.md)**.

---

## What You Need to Replace

Before running, you must customize these files:

### `.cms.env`
| Setting | Replace with |
|---|---|
| `APP_KEY` | Generate via `docker compose exec cms php artisan key:generate --show` |
| `APP_URL` | `http://localhost:8081` (local) or `http://<YOUR_PUBLIC_IP>:8081` (external) |
| `SESSION_DOMAIN` | `localhost` (local) or `<YOUR_PUBLIC_IP>` (external) |
| `NITRO_CLIENT_PATH` | `http://localhost:3000` (local) or `http://<YOUR_PUBLIC_IP>:3000` (external) |

### `nitro/renderer-config.json`
| Setting | Replace with |
|---|---|
| `socket.url` | `ws://localhost:2096` or `ws://<YOUR_PUBLIC_IP>:2096` |
| `asset.url` | `http://127.0.0.1:8080/assets` or `http://<YOUR_PUBLIC_IP>:8080/assets` |
| `image.library.url` | Same pattern — use your IP |
| `hof.furni.url` | Same pattern — use your IP |

### `nitro/ui-config.json`
| Setting | Replace with |
|---|---|
| `socket.url` | Must match renderer-config.json |
| `url.prefix` | `http://127.0.0.1:8081` or `http://<YOUR_PUBLIC_IP>:8081` |

### Database (after containers are running)
| Table | Key | Replace with |
|---|---|---|
| `website_settings` | `avatar_imager` | URL with your IP |
| `website_settings` | `nitro_path` | URL with your IP |
| `website_settings` | `badges_path` | URL with your IP |
| `emulator_settings` | `websockets.whitelist` | `*` for external access |

> **See [SETUP.md](SETUP.md) for exact commands and step-by-step instructions.**

---

## Ports

| Port | Service |
|------|---------|
| 8081 | CMS (website & login) |
| 3000 | Nitro client |
| 2096 | WebSocket (game server) |
| 8080 | Assets server |
| 3310 | MySQL |

---

## Default Login

| | |
|---|---|
| Username | `admin` |
| Password | `admin` |
| Rank | 7 (Owner) |

---

## Requirements

- Docker Desktop
- Git
- Node.js 15+ (for habbo-downloader)
- ~10GB disk space

---

## Documentation

- **[SETUP.md](SETUP.md)** — Complete setup guide with troubleshooting, admin commands, database access, external access, and Codex prompts

---

## Credits

- [thebalaa](https://github.com/thebalaa) — Original clabo-hotel Docker setup
- [Morningstar Team](https://git.krews.org/morningstar/Arcturus-Community) — Arcturus Emulator
- [billsonnn](https://github.com/billsonnn/nitro-react) — Nitro React Client
- [atom-retros](https://github.com/atom-retros/atomcms) — AtomCMS
- [Gurkengewuerz](https://github.com/Gurkengewuerz/nitro-docker) — nitro-docker reference

## License

This setup uses multiple open-source projects under their respective licenses. See individual repos for details.
