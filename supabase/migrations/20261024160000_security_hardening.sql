-- ============================================================================
-- Pokegrammys 2026 — Migració de seguretat (PostgreSQL / Supabase)
-- Fitxer: supabase/migrations/20261024160000_security_hardening.sql
-- ============================================================================
-- QUÈ FA:
--   1. Corregeix l'escalada de privilegis de profiles (CRÍTICA).
--   2. Endureix les funcions SECURITY DEFINER (search_path).
--   3. Valida que els vots corresponguin a nominacions reals.
--   4. Afegeix una finestra de votació i força el timestamp del servidor.
--   5. Redueix permisos de taules sensibles.
--   6. Afegeix auditoria de canvis.
--
-- ABANS D'EXECUTAR:
--   * Fes una còpia de seguretat (Supabase Backup / pg_dump).
--   * Prova-ho en un projecte de staging.
--   * Executa-ho des del SQL Editor de Supabase (rol postgres) o amb la CLI,
--     mai des del client.
--   * Aquest script NO esborra vots. Les consultes de diagnòstic són SELECT.
--   * Les seccions [OPCIONAL] canvien comportament; llegeix-les.
--
-- NOTA SOBRE TRANSACCIONS:
--   El script va embolcallat en BEGIN/COMMIT. Si el teu entorn ja executa
--   la migració dins d'una transacció, pots treure aquestes dues línies.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 0. DIAGNÒSTIC I PRECOMPROVACIONS (només lectura)
-- ============================================================================
-- Aquestes consultes no modifiquen res. Si alguna precomprovació falla,
-- la transacció s'atura ABANS d'aplicar canvis.

-- 0.1 Polítiques actuals de profiles
SELECT
  polname,
  polcmd,
  polroles,
  pg_get_expr(polqual, polrelid) AS using_expr,
  pg_get_expr(polwithcheck, polrelid) AS with_check_expr
FROM pg_policy
WHERE polrelid = 'public.profiles'::regclass;

-- 0.2 Rols existents
SELECT role, count(*) AS total
FROM public.profiles
GROUP BY role
ORDER BY role;

-- 0.3 Precomprovació: rols permesos
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE role NOT IN ('voter', 'admin')
  ) THEN
    RAISE EXCEPTION
      'Hi ha rols no permesos a public.profiles. Revisa-ho amb: SELECT DISTINCT role FROM public.profiles;';
  END IF;
END $$;

-- 0.4 Precomprovació: vots amb categoria o nominat NULL
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.votacion_pokeserie
    WHERE categoria_id IS NULL OR pokecuento_id IS NULL
  ) OR EXISTS (
    SELECT 1 FROM public.votacion_pokefilm
    WHERE categoria_id IS NULL OR pokefilm_id IS NULL
  ) THEN
    RAISE EXCEPTION
      'Hi ha vots amb categoria o nominat NULL. Neteja''ls abans de continuar.';
  END IF;
END $$;

-- 0.5 Precomprovació: vots que no corresponen a cap nominació
-- Si falla, llista'ls amb:
-- SELECT v.* FROM public.votacion_pokeserie v
-- WHERE NOT EXISTS (
--   SELECT 1 FROM public.nominados_pokeserie n
--   WHERE n.categoria_id = v.categoria_id AND n.pokecuento_id = v.pokecuento_id
-- );
-- SELECT v.* FROM public.votacion_pokefilm v
-- WHERE NOT EXISTS (
--   SELECT 1 FROM public.nominados_pokefilm n
--   WHERE n.categoria_id = v.categoria_id AND n.pokefilm_id = v.pokefilm_id
-- );
DO $$
DECLARE
  bad_pokeserie bigint;
  bad_pokefilm bigint;
BEGIN
  SELECT count(*) INTO bad_pokeserie
  FROM public.votacion_pokeserie v
  WHERE NOT EXISTS (
    SELECT 1
    FROM public.nominados_pokeserie n
    WHERE n.categoria_id = v.categoria_id
      AND n.pokecuento_id = v.pokecuento_id
  );

  SELECT count(*) INTO bad_pokefilm
  FROM public.votacion_pokefilm v
  WHERE NOT EXISTS (
    SELECT 1
    FROM public.nominados_pokefilm n
    WHERE n.categoria_id = v.categoria_id
      AND n.pokefilm_id = v.pokefilm_id
  );

  IF bad_pokeserie > 0 OR bad_pokefilm > 0 THEN
    RAISE EXCEPTION
      'Hi ha vots sense nominació (pokeserie=%, pokefilm=%). Revisa''ls i decideix què fer abans d''afegir les FKs.',
      bad_pokeserie, bad_pokefilm;
  END IF;
END $$;

-- 0.6 Precomprovació: votante_id ha de ser UUID (auth.uid() retorna UUID).
-- Si encara és VARCHAR, aplica abans la conversió de src/assets/RLS_SQL.sql
-- o converteix-la manualment amb una còpia de seguretat.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'votacion_pokeserie'
      AND column_name = 'votante_id'
      AND data_type <> 'uuid'
  ) OR EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'votacion_pokefilm'
      AND column_name = 'votante_id'
      AND data_type <> 'uuid'
  ) THEN
    RAISE EXCEPTION
      'votante_id ha de ser UUID. Converteix-lo abans d''aplicar aquesta migració.';
  END IF;
END $$;

-- ============================================================================
-- 1. CRÍTIC: impedir que un usuari es faci admin
-- ============================================================================
-- Problema:
--   La política "Users can update own profile" només tenia USING
--   (auth.uid() = id), sense WITH CHECK que limités el nou valor de role.
--   PostgreSQL reutilitza el USING com a WITH CHECK, així que un usuari
--   podia enviar {"role":"admin"} i superar totes les polítiques is_admin().
--
-- Solució:
--   1. Eliminar la política d'UPDATE de perfils (l'app no edita perfils).
--   2. Revocar INSERT/UPDATE/DELETE al client.
--   3. Afegir un CHECK per limitar els rols.
--   4. Afegir un trigger que bloquegi canvis de role fets per un usuari.

-- 1.1 Eliminar la política vulnerable
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

-- 1.2 Permisos: el client només pot llegir el seu propi perfil
--     REVOKE ALL també treu TRUNCATE/REFERENCES/TRIGGER, que la RLS no protegeix.
REVOKE ALL ON public.profiles FROM anon, authenticated;
GRANT SELECT ON public.profiles TO authenticated;

-- 1.3 Assegurar que la RLS està activada
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 1.4 Restricció de valors permesos
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('voter', 'admin')) NOT VALID;
ALTER TABLE public.profiles VALIDATE CONSTRAINT profiles_role_check;

-- 1.5 Defensa en profunditat: cap usuari final pot canviar el seu role,
--     ni tan sols si algú torna a crear per error una política d'UPDATE.
CREATE OR REPLACE FUNCTION public.prevent_role_self_escalation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  -- auth.uid() és NULL per a service_role i per a SQL directe.
  -- Si hi ha un usuari final a la petició, no pot canviar el role.
  IF auth.uid() IS NOT NULL AND NEW.role IS DISTINCT FROM OLD.role THEN
    RAISE EXCEPTION 'Canvi de role no permès des del client'
      USING ERRCODE = '42501'; -- insufficient_privilege
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.prevent_role_self_escalation() FROM PUBLIC;

DROP TRIGGER IF EXISTS prevent_role_self_escalation ON public.profiles;
CREATE TRIGGER prevent_role_self_escalation
BEFORE UPDATE OF role ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.prevent_role_self_escalation();

-- ============================================================================
-- 2. ENDURIR FUNCIONS SECURITY DEFINER
-- ============================================================================
-- Problema:
--   Les funcions SECURITY DEFINER no fixaven search_path. En Supabase,
--   anon/authenticated normalment no poden crear objectes a public, però
--   és una bona pràctica fixar-lo i qualificar tots els noms.
--
-- Solució:
--   Recrear les funcions amb SET search_path = '' i noms completament
--   qualificats. Revocar EXECUTE de PUBLIC i concedir només el necessari.

-- 2.1 is_admin(): només authenticated l'ha de poder executar
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- 2.2 handle_new_user(): trigger de creació de perfil
--     No cal que ningú l'executi directament; el trigger la invoca.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, role)
  VALUES (NEW.id, 'voter')
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC;

-- Assegura que el trigger apunta a la funció segura.
-- Requereix permisos sobre auth.users (postgres/service_role).
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 3. CONFIGURACIÓ DE LA VOTACIÓ
-- ============================================================================
-- [OPCIONAL] Aquesta secció crea election_settings.
-- Per defecte voting_open = true per NO aturar la votació existent.
-- Canvia-ho a false quan la votació estigui tancada:
--   UPDATE public.election_settings SET voting_open = false WHERE id = true;
--
-- results_published = true manté el comportament actual (resultats públics).
-- Posa-ho a false si no vols publicar resultats fins a la gala.

CREATE TABLE IF NOT EXISTS public.election_settings (
  id boolean PRIMARY KEY DEFAULT true CHECK (id),
  voting_open boolean NOT NULL DEFAULT true,
  opens_at timestamptz,
  closes_at timestamptz,
  results_published boolean NOT NULL DEFAULT true
);

ALTER TABLE public.election_settings
  ADD COLUMN IF NOT EXISTS results_published boolean NOT NULL DEFAULT true;

ALTER TABLE public.election_settings ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.election_settings FROM anon, authenticated;

INSERT INTO public.election_settings (id, voting_open, results_published)
VALUES (true, true, true)
ON CONFLICT (id) DO NOTHING;

-- service_role (només servidor) pot gestionar la configuració.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.election_settings TO service_role;

-- ============================================================================
-- 4. RESULTATS: FUNCIONS PÚBLIQUES NOMÉS D'AGREGATS
-- ============================================================================
-- Si results_published és false, les funcions no retornen res.
-- Les funcions són SECURITY DEFINER i tenen search_path buit.

CREATE OR REPLACE FUNCTION public.get_resultados_pokeserie()
RETURNS TABLE(categoria_id int, pokecuento_id int, votos bigint)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.election_settings
    WHERE id = true
      AND results_published
  ) THEN
    RAISE EXCEPTION 'Els resultats encara no són públics'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    v.categoria_id,
    v.pokecuento_id,
    count(*)::bigint AS votos
  FROM public.votacion_pokeserie v
  GROUP BY v.categoria_id, v.pokecuento_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_resultados_pokeserie() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_resultados_pokeserie() TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.get_resultados_pokefilm()
RETURNS TABLE(categoria_id int, pokefilm_id int, votos bigint)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.election_settings
    WHERE id = true
      AND results_published
  ) THEN
    RAISE EXCEPTION 'Els resultats encara no són públics'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    v.categoria_id,
    v.pokefilm_id,
    count(*)::bigint AS votos
  FROM public.votacion_pokefilm v
  GROUP BY v.categoria_id, v.pokefilm_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_resultados_pokefilm() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_resultados_pokefilm() TO anon, authenticated;

-- Re-concedir les views existents, si n'hi ha.
DO $$
BEGIN
  IF to_regclass('public.resultados_pokeserie') IS NOT NULL THEN
    GRANT SELECT ON public.resultados_pokeserie TO anon, authenticated;
  END IF;

  IF to_regclass('public.resultados_pokefilm') IS NOT NULL THEN
    GRANT SELECT ON public.resultados_pokefilm TO anon, authenticated;
  END IF;
END $$;

-- ============================================================================
-- 5. INTEGRITAT DELS VOTS
-- ============================================================================

-- 5.1 Impedir NULLs a les columnes clau
ALTER TABLE public.votacion_pokeserie
  ALTER COLUMN votante_id SET NOT NULL,
  ALTER COLUMN categoria_id SET NOT NULL,
  ALTER COLUMN pokecuento_id SET NOT NULL;

ALTER TABLE public.votacion_pokefilm
  ALTER COLUMN votante_id SET NOT NULL,
  ALTER COLUMN categoria_id SET NOT NULL,
  ALTER COLUMN pokefilm_id SET NOT NULL;

-- 5.2 Afegir FK composta: un vot només pot apuntar a una nominació real.
-- ON DELETE RESTRICT evita que esborrar una nominació (o el contingut que
-- hi ha darrere) esborri vots implícitament. Si cal netejar, fes-ho
-- explícitament i amb còpia de seguretat.
ALTER TABLE public.votacion_pokeserie
  DROP CONSTRAINT IF EXISTS fk_vote_nomination;
ALTER TABLE public.votacion_pokeserie
  ADD CONSTRAINT fk_vote_nomination
  FOREIGN KEY (categoria_id, pokecuento_id)
  REFERENCES public.nominados_pokeserie (categoria_id, pokecuento_id)
  ON DELETE RESTRICT
  NOT VALID;
ALTER TABLE public.votacion_pokeserie
  VALIDATE CONSTRAINT fk_vote_nomination;

ALTER TABLE public.votacion_pokefilm
  DROP CONSTRAINT IF EXISTS fk_vote_nomination;
ALTER TABLE public.votacion_pokefilm
  ADD CONSTRAINT fk_vote_nomination
  FOREIGN KEY (categoria_id, pokefilm_id)
  REFERENCES public.nominados_pokefilm (categoria_id, pokefilm_id)
  ON DELETE RESTRICT
  NOT VALID;
ALTER TABLE public.votacion_pokefilm
  VALIDATE CONSTRAINT fk_vote_nomination;

-- 5.3 Reduir permisos sobre les taules de vots
--     El client només ha de poder INSERTAR. No ha de poder llegir,
--     actualitzar ni esborrar vots directament.
REVOKE ALL ON public.votacion_pokeserie FROM anon, authenticated;
REVOKE ALL ON public.votacion_pokefilm FROM anon, authenticated;
GRANT INSERT ON public.votacion_pokeserie TO authenticated;
GRANT INSERT ON public.votacion_pokefilm TO authenticated;

-- [OPCIONAL] Si vols forçar IDs generats pel servidor, descomenta:
-- ALTER TABLE public.votacion_pokeserie ALTER COLUMN id SET GENERATED ALWAYS;
-- ALTER TABLE public.votacion_pokefilm ALTER COLUMN id SET GENERATED ALWAYS;

-- ============================================================================
-- 6. FINESTRA DE VOTACIÓ I TIMESTAMP DEL SERVIDOR
-- ============================================================================

CREATE OR REPLACE FUNCTION public.enforce_voting_window()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_open boolean;
BEGIN
  SELECT (
    voting_open
    AND (opens_at IS NULL OR now() >= opens_at)
    AND (closes_at IS NULL OR now() < closes_at)
  )
  INTO v_open
  FROM public.election_settings
  WHERE id = true;

  IF COALESCE(v_open, false) IS NOT TRUE THEN
    RAISE EXCEPTION 'La votació està tancada'
      USING ERRCODE = '42501';
  END IF;

  -- El timestamp sempre l'assigna el servidor.
  NEW.fecha_votacion := now();
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_voting_window() FROM PUBLIC;

DROP TRIGGER IF EXISTS enforce_voting_window_pokeserie ON public.votacion_pokeserie;
CREATE TRIGGER enforce_voting_window_pokeserie
BEFORE INSERT ON public.votacion_pokeserie
FOR EACH ROW
EXECUTE FUNCTION public.enforce_voting_window();

DROP TRIGGER IF EXISTS enforce_voting_window_pokefilm ON public.votacion_pokefilm;
CREATE TRIGGER enforce_voting_window_pokefilm
BEFORE INSERT ON public.votacion_pokefilm
FOR EACH ROW
EXECUTE FUNCTION public.enforce_voting_window();

-- ============================================================================
-- 7. [OPCIONAL] EXIGIR CORREU VERIFICAT
-- ============================================================================
-- ATENCIÓ: Activa-ho només si tens la confirmació de correu activada a
-- Supabase i els usuaris existents tenen email_confirmed_at.
-- Si no, els usuaris actuals no podran votar.
--
-- CREATE OR REPLACE FUNCTION public.is_verified_user()
-- RETURNS boolean
-- LANGUAGE sql
-- STABLE
-- SECURITY DEFINER
-- SET search_path = ''
-- AS $$
--   SELECT EXISTS (
--     SELECT 1
--     FROM auth.users
--     WHERE id = auth.uid()
--       AND email_confirmed_at IS NOT NULL
--   );
-- $$;
--
-- REVOKE ALL ON FUNCTION public.is_verified_user() FROM PUBLIC;
-- GRANT EXECUTE ON FUNCTION public.is_verified_user() TO authenticated;
--
-- DROP POLICY IF EXISTS "Authenticated users can vote pokeserie" ON public.votacion_pokeserie;
-- CREATE POLICY "Verified users can vote pokeserie"
-- ON public.votacion_pokeserie
-- FOR INSERT
-- TO authenticated
-- WITH CHECK (
--   auth.uid() = votante_id
--   AND public.is_verified_user()
-- );
--
-- DROP POLICY IF EXISTS "Authenticated users can vote pokefilm" ON public.votacion_pokefilm;
-- CREATE POLICY "Verified users can vote pokefilm"
-- ON public.votacion_pokefilm
-- FOR INSERT
-- TO authenticated
-- WITH CHECK (
--   auth.uid() = votante_id
--   AND public.is_verified_user()
-- );

-- ============================================================================
-- 8. PERMISOS DE CONTINGUT I RLS
-- ============================================================================
-- Les taules de contingut han de ser de lectura pública, però només els
-- admins (via RLS is_admin) hi poden escriure. Revoca DML a anon.

-- anon: només lectura. REVOKE ALL evita TRUNCATE/REFERENCES/TRIGGER.
REVOKE ALL ON
  public.pokecuento,
  public.pokefilm,
  public.categorias_pokeserie,
  public.categorias_pokefilm,
  public.nominados_pokeserie,
  public.nominados_pokefilm
FROM anon;

GRANT SELECT ON
  public.pokecuento,
  public.pokefilm,
  public.categorias_pokeserie,
  public.categorias_pokefilm,
  public.nominados_pokeserie,
  public.nominados_pokefilm
TO anon;

-- authenticated: l'admin necessita CRUD, però la RLS is_admin() el limita.
-- Li traiem TRUNCATE/REFERENCES/TRIGGER perquè la RLS no cobreix aquests permisos.
GRANT SELECT, INSERT, UPDATE, DELETE ON
  public.pokecuento,
  public.pokefilm,
  public.categorias_pokeserie,
  public.categorias_pokefilm,
  public.nominados_pokeserie,
  public.nominados_pokefilm
TO authenticated;

REVOKE TRUNCATE, REFERENCES, TRIGGER ON
  public.pokecuento,
  public.pokefilm,
  public.categorias_pokeserie,
  public.categorias_pokefilm,
  public.nominados_pokeserie,
  public.nominados_pokefilm
FROM authenticated;

-- Assegurar RLS a totes les taules
ALTER TABLE public.pokecuento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pokefilm ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias_pokeserie ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias_pokefilm ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nominados_pokeserie ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nominados_pokefilm ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.votacion_pokeserie ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.votacion_pokefilm ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 9. AUDITORIA
-- ============================================================================
-- Registra canvis a profiles i contingut. No registra vots per privacitat.
-- Només postgres/service_role hi poden accedir.

CREATE TABLE IF NOT EXISTS public.security_audit (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  actor uuid,
  actor_role text,
  action text NOT NULL,
  table_name text NOT NULL,
  row_id text,
  old_data jsonb,
  new_data jsonb
);

ALTER TABLE public.security_audit ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.security_audit FROM anon, authenticated;
GRANT SELECT ON public.security_audit TO service_role;

CREATE INDEX IF NOT EXISTS idx_security_audit_occurred_at
  ON public.security_audit (occurred_at DESC);

CREATE OR REPLACE FUNCTION public.audit_row_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_row_id text;
BEGIN
  v_row_id := COALESCE(
    to_jsonb(NEW)->>'id',
    to_jsonb(OLD)->>'id',
    (to_jsonb(NEW)->>'categoria_id') || ':' ||
      COALESCE(to_jsonb(NEW)->>'pokecuento_id', to_jsonb(NEW)->>'pokefilm_id'),
    (to_jsonb(OLD)->>'categoria_id') || ':' ||
      COALESCE(to_jsonb(OLD)->>'pokecuento_id', to_jsonb(OLD)->>'pokefilm_id')
  );

  INSERT INTO public.security_audit (
    actor, actor_role, action, table_name, row_id, old_data, new_data
  ) VALUES (
    auth.uid(),
    COALESCE(NULLIF(current_setting('request.jwt.claim.role', true), ''), session_user),
    TG_OP,
    TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
    v_row_id,
    CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) END
  );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.audit_row_change() FROM PUBLIC;

-- Crea/renova els triggers d'auditoria a les taules de contingut i perfils.
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'public.profiles',
    'public.pokecuento',
    'public.pokefilm',
    'public.categorias_pokeserie',
    'public.categorias_pokefilm',
    'public.nominados_pokeserie',
    'public.nominados_pokefilm'
  ]
  LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS %I ON %s',
      'audit_' || split_part(t, '.', 2),
      t
    );
    EXECUTE format(
      'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON %s '
      'FOR EACH ROW EXECUTE FUNCTION public.audit_row_change()',
      'audit_' || split_part(t, '.', 2),
      t
    );
  END LOOP;
END $$;

-- ============================================================================
-- 10. VERIFICACIÓ FINAL (només lectura)
-- ============================================================================

-- 10.1 Polítiques de profiles: no hi ha d'haver cap UPDATE per a authenticated
SELECT polname, polcmd, polroles
FROM pg_policy
WHERE polrelid = 'public.profiles'::regclass;

-- 10.2 Rols existents
SELECT role, count(*) AS total
FROM public.profiles
GROUP BY role
ORDER BY role;

-- 10.3 Funcions i search_path
SELECT
  p.proname,
  p.prosecdef AS security_definer,
  p.proconfig
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'is_admin',
    'handle_new_user',
    'get_resultados_pokeserie',
    'get_resultados_pokefilm',
    'enforce_voting_window',
    'audit_row_change',
    'prevent_role_self_escalation'
  )
ORDER BY p.proname;

-- 10.4 RLS activa a totes les taules
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

COMMIT;

-- ============================================================================
-- 11. ROLLBACK (només si cal; NO reintroduïu la política vulnerable)
-- ============================================================================
-- Abans d'eliminar security_audit, elimina els triggers audit_*:
-- DROP TRIGGER IF EXISTS audit_profiles ON public.profiles;
-- DROP TRIGGER IF EXISTS audit_pokecuento ON public.pokecuento;
-- DROP TRIGGER IF EXISTS audit_pokefilm ON public.pokefilm;
-- DROP TRIGGER IF EXISTS audit_categorias_pokeserie ON public.categorias_pokeserie;
-- DROP TRIGGER IF EXISTS audit_categorias_pokefilm ON public.categorias_pokefilm;
-- DROP TRIGGER IF EXISTS audit_nominados_pokeserie ON public.nominados_pokeserie;
-- DROP TRIGGER IF EXISTS audit_nominados_pokefilm ON public.nominados_pokefilm;
--
-- DROP TRIGGER IF EXISTS enforce_voting_window_pokeserie ON public.votacion_pokeserie;
-- DROP TRIGGER IF EXISTS enforce_voting_window_pokefilm ON public.votacion_pokefilm;
-- DROP FUNCTION IF EXISTS public.enforce_voting_window();
--
-- ALTER TABLE public.votacion_pokeserie DROP CONSTRAINT IF EXISTS fk_vote_nomination;
-- ALTER TABLE public.votacion_pokefilm DROP CONSTRAINT IF EXISTS fk_vote_nomination;
--
-- DROP TRIGGER IF EXISTS prevent_role_self_escalation ON public.profiles;
-- DROP FUNCTION IF EXISTS public.prevent_role_self_escalation();
--
-- DROP FUNCTION IF EXISTS public.audit_row_change();
-- DROP TABLE IF EXISTS public.security_audit;
-- DROP TABLE IF EXISTS public.election_settings;
--
-- ATENCIÓ: no torneu a crear "Users can update own profile" amb USING sol.
-- ============================================================================
