# Host for the recital

`ergentics.com` already uses Cloudflare nameservers (`frida.ns.cloudflare.com` and `neil.ns.cloudflare.com`). The address answers from Cloudflare. This environment can resolve that name and reach the edge. It cannot change the site.

A request from this machine to `https://ergentics.com` receives HTTP 403 with `cf-mitigated: challenge`. The existing page body is not visible from that request. The Cloudflare session can read the Ergentics account. It can list Workers. It cannot open an asset upload session: the API returns no access to that resource. `demos/recital` installs Wrangler 4.151.0. `npx wrangler whoami` in that directory still reports no login. Nothing has been deployed.

## Adapter

The first host is a Worker that serves static assets. The asset directory is `demos/recital/`. `wrangler.jsonc` in that directory names the Worker `ergentics-recital`. It serves `index.html`, `hello-440.html`, `commitment_reader.wasm`, and `commitment_guest.wasm`. It does not run the Rails index, store rows, or issue a capability.

`ergentics.com/research` and `ergentics.com/research/*` already run the Worker `ergentics-research-path`. That script sets `script-src 'self'` and does not allow `wasm-unsafe-eval`. The recital instantiates two modules, so it does not belong inside that policy. This file does not change that Worker.

The custom domain is `ergentics.com`. Attaching it replaces whatever the apex serves today. That attachment waits for a person who can see the current page and who is logged into the zone. The command, after that login, is:

```sh
cd demos/recital && npx wrangler deploy
```

Routes and the DNS record stay a dashboard step. This file does not create them.

## Move

The apex `ergentics.com` is the Pages project `ergentics-site` (`ergentics-site.pages.dev`). `https://ergentics.com/products` is that site. Music Theory is already a product card there, marked in development. `https://ergentics.com/products/music-theory` is 404. `https://ergentics.com/research/propulsion.html` is a working paper served by the Worker `ergentics-research-path`, which owns `ergentics.com/research` and `ergentics.com/research/*`. A Worker route is more specific than the Pages site, which is why those research URLs are not Pages.

The recital gets its own working page. It does not replace `/products`, and it does not join the research Worker's script policy. That policy is `script-src 'self'` and does not allow `wasm-unsafe-eval`, so a module instantiated on that Worker would not run. This plan does not edit `ergentics-research-path`.

Two preview types, two paths, one Worker when a write-capable login exists:

| Path | Preview | What plays |
|---|---|---|
| `https://ergentics.com/products/music-theory/` | Music Theory, the product card that already exists | Public recital pages. The first is Hello, 440: play, then the in-page ratio check. The private lyre engine is not copied. |
| `https://ergentics.com/research/recital/` | Foundations parity | The Rust reader and the embedded Swift guest. Each constructs the synthetic-base state. The page compares the hex strings. |

The routes to add, and no others, are `ergentics.com/products/music-theory`, `ergentics.com/products/music-theory/*`, `ergentics.com/research/recital`, and `ergentics.com/research/recital/*`. The more specific research routes stay off `propulsion.html`. The Worker `ergentics-recital` maps those prefixes onto its own files and sets `script-src 'self' 'wasm-unsafe-eval'` only on its own responses. `wrangler.jsonc` still has no route and no custom domain, so a deploy of that file does not attach the apex. The Music Theory card on `/products` can later link to its preview. That link is a change in the Pages project, which is not this repository.

This session can read the account and cannot upload a Worker or add a route. The page is not deployed.

R2 stays unused. The recital is a few HTML files and two small modules. Workers static assets can serve those bytes. A bucket would be a second copy of the same files, and it would not be the object store.

The store stays unimplemented. Section 9 left ObjectID, durable commit recovery, and backend adapters unimplemented. The Rails index is a local reading of the traceability JSON. An R2 object is not a `StateID` and not a commit. Starting a bucket for the recital would not start that store.

When a store is designed, it needs its own contract: what is stored, who may write it, and how a reader checks current authority. That design is not this move.

## What this is not

The 60 MB Swift WASI command is not what the browser loads. The page loads two small modules. The Rust `wasm32-unknown-unknown` reader and the embedded Swift guest each construct the synthetic-base state. The page compares those two hex strings. Neither module receives the other's output.
