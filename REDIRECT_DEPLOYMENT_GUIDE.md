# Redirect Deployment Guide

This project moved:

- Old URL: `/phase1-5.html`
- New canonical URL: `/phase4-7.html`
- Redirect type: `301` (permanent)

## Configs already in this repo

- IIS: `web.config`
- Netlify-style: `_redirects`
- Vercel: `vercel.json`
- Azure Static Web Apps: `staticwebapp.config.json`
- Firebase Hosting (Google Cloud): `firebase.json`
- Client-side fallback: `phase1-5.html` (meta/js redirect)

## Google Cloud Platform

### 1) Firebase Hosting (recommended for static sites)

Already configured in `firebase.json`:

```json
{
  "hosting": {
    "redirects": [
      {
        "source": "/phase1-5.html",
        "destination": "/phase4-7.html",
        "type": 301
      }
    ]
  }
}
```

Deploy:

```bash
firebase deploy --only hosting
```

### 2) App Engine (Standard/Flexible)

If you deploy behind App Engine routing, add a redirect handler in `app.yaml`.

Example:

```yaml
runtime: nodejs20
handlers:
  - url: /phase1-5.html
    static_files: phase1-5.html
    upload: phase1-5.html
    redirect_http_response_code: 301
    secure: always
```

Notes:

- App Engine redirect options vary by runtime and serving model.
- If you serve via custom app/server code, do redirect in app middleware/router instead.

### 3) Cloud Storage + Cloud CDN / Load Balancer

GCS static website hosting does not natively support path-level 301 rules like this.
Use one of these approaches:

1. Put Cloud HTTP(S) Load Balancer in front and add a URL redirect rule.
2. Use Cloud Run/Functions as an edge redirect service for legacy paths.
3. Keep the existing HTML fallback in `phase1-5.html`.

## Validation checklist

After deployment, verify:

1. `GET /phase1-5.html` returns `301` (server-side), or falls back to client redirect if host cannot do server redirects.
2. Location points to `/phase4-7.html`.
3. `GET /phase4-7.html` returns `200`.
4. Internal links in pages reference `phase4-7.html`.

## Quick test commands

```bash
curl -I https://<your-domain>/phase1-5.html
curl -I https://<your-domain>/phase4-7.html
```

Expected:

- First response: `301` with `Location: /phase4-7.html`
- Second response: `200`
