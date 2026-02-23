# Habbo Clone --- Missing Catalog & Inventory Thumbnails Fix

Complete setup guide for running a Habbo Hotel private server using Arcturus Morningstar 4.0, Nitro React client, and AtomCMS via Docker Compose.

> **Fork of [thebalaa/clabo-hotel](https://github.com/thebalaa/clabo-hotel)** with fixes for PHP 8.4, CSRF errors, missing catalog icons, external access, rate limiting, and Windows localhost deployment.

------------------------------------------------------------------------

## Bug

The **Catalog/Shop**, **Inventory**, and **Building catalog** grids show
blank thumbnails.

-   Left-side item grid icons → ❌ Missing
-   Right-side preview panel → ✅ Works
-   `.nitro` 3D bundles render correctly

This affects: - Shop (all tabs) - Inventory - Builder catalog

------------------------------------------------------------------------

## Root Cause

The furniture **icon PNG files were never downloaded**.

Important distinction:

  Asset Type            What it is               Status
  --------------------- ------------------------ ---------
  Nitro bundles         3D furniture rendering   Working
  Catalog icons (PNG)   Small UI thumbnails      Missing

The script:

    assets-build.sh

only converts:

    SWF → Nitro bundles

However, the catalog and inventory thumbnails are **separate PNG files**
stored in:

    assets/swf/dcr/hof_furni/

These must be downloaded directly from Habbo's CDN using
**habbo-downloader**.

------------------------------------------------------------------------

## Fix

### 1) Install `habbo-downloader`

Requires **Node.js 15+**

``` bash
npm i -g habbo-downloader
```

------------------------------------------------------------------------

### 2) Download the icon files

``` bash
cd C:\clabo-hotel
habbo-downloader --output ./assets/swf --domain com --command icons
```

This will download icons into:

    assets/swf/dcr/hof_furni/icons/

------------------------------------------------------------------------

### 3) Move icons to the correct directory

Nitro expects the PNG files in the **root of `hof_furni`**, not inside
the `icons` subfolder.

``` bash
cp -n assets/swf/dcr/hof_furni/icons/* assets/swf/dcr/hof_furni/
```

------------------------------------------------------------------------

### 4) Verify renderer configuration

Open:

    renderer-config.json

Confirm the path:

``` json
"hof.furni.url": "http://127.0.0.1:8080/swf/dcr/hof_furni/"
```

------------------------------------------------------------------------

## Reload the Client

No container rebuild is needed.

The `assets` directory is volume-mounted into the **nginx assets
container**.

Just hard refresh:

    Ctrl + Shift + R

------------------------------------------------------------------------

## If Icons Still Do Not Appear

Clear the nginx cache:

``` bash
docker compose restart assets
```

------------------------------------------------------------------------

## ✅ Expected Result

After refresh:

-   Shop thumbnails appear
-   Inventory icons appear
-   Builder catalog icons appear
-   Right preview panel still works

------------------------------------------------------------------------

## Why This Happens

Nitro uses **two completely separate asset systems**:

1.  **Nitro bundles (.nitro)** → 3D object rendering
2.  **hof_furni PNG icons** → UI thumbnails

`assets-build.sh` only handles the first.

The UI catalog relies entirely on the second.

------------------------------------------------------------------------

Suggested save path in repo:

    docs/fixing-missing-catalog-icons.md
