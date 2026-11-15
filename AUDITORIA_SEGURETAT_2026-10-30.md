# Auditoria de seguretat — Pokegrammys2026
**Data:** 30 d'octubre de 2026
**Abast:** frontend (Vue/Supabase), esquema SQL (migracions), CI (GitHub Actions), configuració de Supabase.
**Estat inicial (verificat en producció amb la clau anon):** la migració `supabase/migrations/20261024160000_security_hardening.sql` ja està aplicada i la base està molt blindada. Els punts següents són les millores pendents.
**Estat d'execució (30/10/2026):** aplicats i verificats (build + lint OK) els canvis 1, 2, 3, 4, 6 i 8. Pendents de decidir manualment: 5, 7, 9 i 10.

**Actualització (15/11/2026):** decisions del responsable:
- Punt 1 (Redirect URLs): **descartat** — la verificació per correu està desactivada.
- Punt 7 (CAPTCHA) i 6 (rate limits): **descartats** — projecte petit i temporal, sense risc de bots.
- Punt 3 (contrasenya mínima 8): **aplicat al codi** (`RegisterView` `minlength=8`); cal posar el mínim 8 també al Dashboard per tenir la protecció al servidor.
- Registre adaptat: amb confirmació per correu desactivada, `signUp` retorna sessió i l'usuari entra directament a `/Home`.
- Punts 4 (leaked passwords) i 5 (email enumeration): **opcionals, no aplicats per decisió** (projecte petit).
- Queden com a opcions: punt 9 (rotació de la clau anon) i punt 10 (Linter de la BD).

---

## Stat global

| # | Canvi | Prioritat | On |
|---|-------|-----------|----|
| 1 | Missatges d'error genèrics a les CRUD d'admin | Mitjana-baixa | 4 components admin |
| 2 | `emailRedirectTo` al registre (~ GH Pages) | Mitjana | `RegisterView.vue` |
| 3 | Flux "Has oblidat la contrasenya?" (reset) | Mitjana | vista nova + `LoginViw.vue` |
| 4 | Frame-buster anti-clickjacking a `index.html` | Baixa | `index.html` |
| 5 | Resultats només per usuaris autenticats (opcional) | Decisió disseny | migració SQL nova |
| 6 | Vots: tolerància a 23505 (ja votat) sense perdre el lots | Baixa | `VotingView.vue` |
| 7 | CAPTCHA + límits de taxa + min contrasenya (manual, Dashboard) | Mitjana | Dashboard Supabase |
| 8 | gitleaks a CI | Baixa | workflow nou |
| 9 | Rotació clau anon → `sb_publishable_` (opcional) | Baixa | Dashboard + git |
| 10 | Revisió final amb Supabase Doctor/Linter | Baixa | Dashboard SQL |

---

## 1. Missatges d'error genèrics a les CRUD d'admin
**Fitxers:** `src/components/admin/PokecuentoCrud.vue`, `PokefilmCrud.vue`, `CategoriaCrud.vue`, `NominatsCrud.vue`

**Problema:** aquestes components fan `error.value = err.message` i mostren el missatge cru de PostgREST a la UI, que pot filtrar detalls interns (taules, constraints, permisos).

**Canvis:**
- Substituir tots els `err.message` per un missatge genèric i traduït (`admin.errorGeneric`); mantener el detall només a `console.error`.
- Cas especial NominatsCrud: conservar el missatge específic de duplicat (error `23505`), però la resta genèric.
- Afegir la clau `admin.errorGeneric` als 4 fitxers de locale (`ca.json`, `es.json`, `en.json`, `ru.json`).

## 2. `emailRedirectTo` al registre
**Fitxer:** `src/views/RegisterView.vue`

**Problema:** `supabase.auth.signUp()` no defineix `emailRedirectTo`; el link de confirmació pot aterrar a un valor maldestí o fora de `/Pokegrammys2026/` a GitHub Pages.

**Canvis:**
```js
await supabase.auth.signUp({
  email: email.value,
  password: password.value,
  options: {
    emailRedirectTo: `${window.location.origin}/Pokegrammys2026/`,
  },
})
```
- Fer-ho RESOLUT amb `import.meta.env.BASE_URL` (no hardcodejar) perquè el `vite.config.js` ja té `base: '/Pokegrammys2026/'`.

## 3. Flux de recuperació de contrasenya
**Fitxers:** vista nova `src/views/ResetPasswordView.vue`, `src/router/index.js`, `src/views/LoginViw.vue`, `src/App.vue` (nav si cal), 4 fitxers de locale.

**Problema:** un usuari que oblidés la contrasenya és bloquejat totalment.

**Canvis:**
- Vista amb @input de correu → `supabase.auth.resetPasswordForEmail(email, { redirectTo: BASE_URL + 'reset' })`.
- Vista de setejar contrasenya nova (s'entra via el link del correu amb sessió temporal): `supabase.auth.updateUser({ password })`.
- Rutes: `/Reset` (nom de `ResetPassword`), **pública** al `publicRoutes` del router.
- Enllaç "Has oblidat la contrasenya?" a la pàgina de login.
- Missatges genèrics (no filtrar si el correu existeix).

## 4. Frame-buster anti-clickjacking
**Fitxer:** `index.html`

**Problema:** GitHub Pages no permet headers (`X-Frame-Options`), i `frame-ancestors` no s'aplica dins `<meta>` CSP.

**Canvis:** script mínim inline (nota: caldrà afegir-ho com a hash/excepció o moure a JS bundlitzat — resolem com a "inline-unsafe inicialment" o via petit escript dins el bundle):
- Punt 1: petit `style.display` — tast: si `window.self !== window.top` → redirigir o tancar.
- Preferible: fer-ho dins `src/main.js` o `App.vue` `onMounted`, ja que CSP deixa només scripts `'self'`.

## 5. (Opcional / decisió) Resultats només autenticats
**Fitxer:** migració SQL nova `supabase/migrations/20261030_restrict_results_to_authed.sql`

**Problema verificat:** amb només la clau anon es pot demanar `get_resultados_pokeserie()`/`get_resultados_pokefilm()`-ISH des de fora de l'app (sense sessió).

**Canvis:**
```sql
REVOKE EXECUTE ON FUNCTION public.get_resultados_pokeserie() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_resultados_pokefilm() FROM anon;
-- (sigui tamé als views resultados_* si encara existeixen)
```
- **Només aplicar-ho si es vol que reclamar resultats fora de l'app sigui impossible fin de gala.** Sinó: deixar-ho com está, però verificar `results_published = false` quan vulguem.

## 6. Vots: no perdre tot el lots si hi ha un duplicat
**Fitxer:** `src/views/VotingView.vue`

**Problema:** es fan totes les vots en un sol insert; si n'hi ha un duplicat (error 23505), es perd tot.

**Canvis:**
- Mantenir el codi que és, però en el `catch` enviar un `insert` de cada disparat un per un i informar resultats correctes.
- (Alternativa futura) RPC `submit_all_votes` per fer-los en una única transacció al servidor.

## 7. Configuració del Dashboard de Supabase (manual, no codi)
- **Auth > Rate Limits:** configurar límits a confirm/signup, OTP, resend, reset-password.
- **Auth > CAPTCHA (Turnstile):** activar per signup (cal claus site/secret + integrar el widget al `RegisterView.vue`).
- **Auth > Email:** minimum password length ≥ 8.
- **Auth > Security:** prevent email enumeration on / outing.
- Si es desitga: restreindre dominis de correu al registre.
- (Nota: la integració CAPTCHA sí genera codi a frontend — es farà quan es decideixi.)

## 8. gitleaks a CI
**Fitxer:** workflow nou `.github/workflows/gitleaks.yml`

**Canvis:**
- Escannejar PRs/pushes amb acció fixada a SHA.
- Opcional: activar Push Protection de GitHub Advanced Security.

## 9. (Opcional) Rotació de clau anon
**Justificat:** el `.env` real (URL + anon key + publishable key) està a l'historial públic (commits `8c26dd7`, `25efbc6»). Per disseny és pública i RLS ho aguanta — NO és un accident greu.
- Al Dashboard: crear nova `sb_publishable_` key i revocar la antiga.
- Sobre git: netejar història amb `git filter-repo` i force-push (o deixar-ho, com que són claus públiques per disseny).
- Actualitzar `.env`, `.env.example`, GitHub Variables i README.

## 10. Revisió final
- Executar supabase doctor / advisories del SQL Editor, revisar "Database > Linter" (RLS ben activat, etc.).
- Verificar que `results_published` té el valor desitjat.
- Repas dels permisos de schemas exposats (Settings > API: només `public`).

---

## Canvi 11. Et deixo notes addicionals amb mesures alternatives
(no obligatòries, però considerades dins la auditoria)
- v-html a `App.vue` (banderes) = **OK** — són SVG estàtic hardcodejat, no dades d'usuari.
- `<img :src="item.imagenurl">` = **OK** — CSP `img-src 'self' data: https:` bloqueja esquemes perillosos; només admins poden escriure URLs.
- Tota l'injecció SQL de Supabase via PostgREST és parametizada — no és un problema.
- `ensureInit()` del guards de router — OK, evita el bypass de sessió inicial.

**Execució dins ordre lògic:** 1 → 2 → 4 → 6 → 3 → 8 → (7, 9, 5, 10 segons decisions).
