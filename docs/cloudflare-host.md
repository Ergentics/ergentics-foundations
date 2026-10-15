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

## Move

This is the move: add the recital as a page on the site that already publishes `https://ergentics.com/research/propulsion.html`. It is not a replacement of that site. The move is recorded here. It is not deployed.

`/research/propulsion.html` is the pattern for how another area handles material: one HTML document at a path under the zone. This environment cannot read that document. A request receives HTTP 403 with `cf-mitigated: challenge`, so the layout, scripts, and asset paths on that page are not known here. The adapter does not guess them.

The Worker `ergentics-recital` serves only the recital files. It does not become the origin for `ergentics.com`. A later route, after a person who can open the propulsion page confirms the fit, is a path such as `ergentics.com/recital` or `ergentics.com/research/<name>.html`. The existing research pages stay on the current origin. `wrangler.jsonc` has no route and no custom domain, so a deploy of this config does not attach the apex.

R2 stays unused. The recital is a few HTML files and one small module. Workers static assets can serve those bytes. A bucket would be a second copy of the same files, and it would not be the object store.

The store stays unimplemented. Section 9 left ObjectID, durable commit recovery, and backend adapters unimplemented. The Rails index is a local reading of the traceability JSON. An R2 object is not a `StateID` and not a commit. Starting a bucket for the recital would not start that store.

When a store is designed, it needs its own contract: what is stored, who may write it, and how a reader checks current authority. That design is not this move.

## What this is not

The Swift WASI probe is not what the browser loads. The page loads the Rust `wasm32-unknown-unknown` module.
