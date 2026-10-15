# Host for the recital

`ergentics.com` already uses Cloudflare nameservers (`frida.ns.cloudflare.com` and `neil.ns.cloudflare.com`). The address answers from Cloudflare. This environment can resolve that name and reach the edge. It cannot change the site.

A request from this machine to `https://ergentics.com` receives HTTP 403 with `cf-mitigated: challenge`. The existing page body is not visible here. The Cloudflare tool in this session asked for a login and the login timed out. Wrangler is not installed and no API token is present. Nothing has been deployed.

## Adapter

The first host is a Worker that serves static assets. The asset directory is `demos/recital/`. `wrangler.jsonc` in that directory names the Worker `ergentics-recital`. It serves `index.html`, `hello-440.html`, and `commitment_reader.wasm`. It does not run the Rails index, store rows, or issue a capability.

The custom domain is `ergentics.com`. Attaching it replaces whatever the apex serves today. That attachment waits for a person who can see the current page and who is logged into the zone. The command, after that login, is:

```sh
npx wrangler deploy --config demos/recital/wrangler.jsonc
```

Routes and the DNS record stay a dashboard step. This file does not create them.

## What this is not

The roadmap item for Cloudflare/R2 storage is still unstarted. A static recital host is not that store. The Swift WASI probe is not what the browser loads. The page loads the Rust `wasm32-unknown-unknown` module.
