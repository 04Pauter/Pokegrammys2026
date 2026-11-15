# Pokegrammys2026

This template should help get you started developing with Vue 3 in Vite.

## Recommended IDE Setup

[VS Code](https://code.visualstudio.com/) + [Vue (Official)](https://marketplace.visualstudio.com/items?itemName=Vue.volar) (and disable Vetur).

## Recommended Browser Setup

- Chromium-based browsers (Chrome, Edge, Brave, etc.):
  - [Vue.js devtools](https://chromewebstore.google.com/detail/vuejs-devtools/nhdogjmejiglipccpnnnanhbledajbpd)
  - [Turn on Custom Object Formatter in Chrome DevTools](http://bit.ly/object-formatters)
- Firefox:
  - [Vue.js devtools](https://addons.mozilla.org/en-US/firefox/addon/vue-js-devtools/)
  - [Turn on Custom Object Formatter in Firefox DevTools](https://fxdx.dev/firefox-devtools-custom-object-formatters/)

## Customize configuration

See [Vite Configuration Reference](https://vite.dev/config/).

## Project Setup

```sh
pnpm install
```

### Compile and Hot-Reload for Development

```sh
pnpm dev
```

### Compile and Minify for Production

```sh
pnpm build
```

### Lint with [ESLint](https://eslint.org/)

```sh
pnpm lint
```

## Seguretat i desplegament

### Variables d'entorn

Copia `.env.example` a `.env` i omple la URL i la clau anon/publishable de
Supabase. No posis mai `service_role`, contrasenyes de base de dades ni secrets
de SMTP/CAPTCHA en variables `VITE_*`: Vite les incrusta al bundle públic.

### Migració de base de dades

La migració de seguretat és
`supabase/migrations/20261024160000_security_hardening.sql`. S'ha validat en un
PostgreSQL local amb un esquema tipus Supabase, però **cal provar-la en staging
abans de producció** i fer una còpia de seguretat. La migració:

- elimina la política d'UPDATE de `profiles` que permetia fer-se admin;
- revoca INSERT/UPDATE/DELETE del client sobre `profiles` i els vots;
- afegeix FKs vot→nominació, finestra de votació, timestamp del servidor i auditoria;
- manté el comportament actual amb `voting_open = true` i `results_published = true`.

Per tancar la votació o amagar els resultats:

```sql
UPDATE public.election_settings SET voting_open = false WHERE id = true;
UPDATE public.election_settings SET results_published = false WHERE id = true;
```

Aquesta taula només és accessible amb `service_role` o des del panell SQL.

Nota: la FK vot→nominació és `ON DELETE RESTRICT`. No es pot esborrar una
nominació que ja té vots; cal netejar els vots explícitament abans.

El fitxer inclou `BEGIN`/`COMMIT`. Si la teva eina ja embolcalla les migracions
en una transacció, pots treure aquestes dues línies.

### GitHub Pages

El workflow de desplegament fa servir pnpm i llegeix `VITE_SUPABASE_URL` i
`VITE_SUPABASE_ANON_KEY` (o `VITE_SUPABASE_PUBLISHABLE_KEY`) de les variables
d'Accions del repositori (Settings > Secrets and variables > Actions >
Variables). Configura-les abans de fusionar a `GHPage`: el fitxer `.env` ja no
es versiona.

La CSP s'injecta només al build de producció. Si canvies de projecte Supabase,
actualitza `connect-src` a `vite.config.js`.
