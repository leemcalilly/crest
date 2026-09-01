# Deploying crest

crest is a single container: Rails 8, SQLite, Solid Queue/Cache/Cable, Thruster.
It holds **no secrets** — no accounts, no email, no third-party keys — so there
is no master key to move and no credential file to manage on the box.

## What the container needs

| Variable | Why |
|---|---|
| `SECRET_KEY_BASE` | Session signing. Any 64-char hex value; generate once and keep it. |
| `APP_HOST` | The hostname it answers for. Defaults to `crest.soccer`. |

Nothing else. No `RAILS_MASTER_KEY` is required.

## First boot builds its own database

The entrypoint runs `db:prepare`, which creates the SQLite databases and runs
`db/seeds.rb`. Seeding imports `db/source/*.csv` — about three seconds for 795
matches, 174 scorers and 945 goals. The source files ship inside the image, so a
cold container needs no network access to populate itself.

Storage lives under `/rails/storage`, which ONCE persists and backs up.

## Steps

1. **DNS first, grey-cloud.** Point an `A` record at the box with the proxy
   **off**, so the certificate can issue against the real origin.
2. **Verify it resolves** before deploying: `dig +short <hostname>`.
3. **Deploy**, giving it a secret and the hostname.
4. **Watch for at least sixty seconds.** A crash loop hides behind the first
   healthy `200` — a container can serve one request and then die on the next
   boot cycle. `/up` is the health endpoint and is excluded from both the SSL
   redirect and host authorization.
5. **Then turn the proxy on**, set TLS to Full (Strict), and enable Always Use
   HTTPS.

## HTTPS is not optional

WebMCP requires a secure context. `document.modelContext` does not exist on a
page served over plain HTTP, so the tools silently never register. If the site
loads but the header reads "Site tools · not supported here" in a browser you
know supports WebMCP, check the scheme first.

## Checking a live deploy

```bash
curl -s https://<hostname>/up                      # health
curl -s https://<hostname>/cycles/1994.json | head # the JSON an agent reads
curl -s https://<hostname>/ | grep -c model-context-manifest   # should print 1
```

The third is the one that matters: if the manifest is missing from the HTML,
no tools will register no matter what the browser supports.
