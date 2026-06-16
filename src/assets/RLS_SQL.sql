-- =========================================================
-- ACTIVAR RLS
-- =========================================================

ALTER TABLE Pokecuento ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorias_pokeserie ENABLE ROW LEVEL SECURITY;
ALTER TABLE nominados_pokeserie ENABLE ROW LEVEL SECURITY;
ALTER TABLE votacion_pokeserie ENABLE ROW LEVEL SECURITY;

ALTER TABLE Pokefilm ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorias_pokefilm ENABLE ROW LEVEL SECURITY;
ALTER TABLE nominados_pokefilm ENABLE ROW LEVEL SECURITY;
ALTER TABLE votacion_pokefilm ENABLE ROW LEVEL SECURITY;

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;


-- =========================================================
-- POLICIES DE LECTURA PÚBLICA
-- =========================================================

CREATE POLICY "Public read Pokecuento"
ON Pokecuento
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Public read categorias_pokeserie"
ON categorias_pokeserie
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Public read nominados_pokeserie"
ON nominados_pokeserie
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Public read Pokefilm"
ON Pokefilm
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Public read categorias_pokefilm"
ON categorias_pokefilm
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Public read nominados_pokefilm"
ON nominados_pokefilm
FOR SELECT
TO anon, authenticated
USING (true);


-- =========================================================
-- NETEJAR VOTACIONS ANTIGUES
-- IMPORTANT si votante_id NO era UUID abans
-- =========================================================

DELETE FROM votacion_pokeserie;
DELETE FROM votacion_pokefilm;


-- =========================================================
-- PROTEGIR VOTACIONS AMB AUTH
-- mantenint votante_id
-- =========================================================

-- Eliminar restriccions antigues
ALTER TABLE votacion_pokeserie
DROP CONSTRAINT IF EXISTS votacion_pokeserie_votante_id_categoria_id_key;

ALTER TABLE votacion_pokefilm
DROP CONSTRAINT IF EXISTS votacion_pokefilm_votante_id_categoria_id_key;


-- Convertir votante_id a UUID
ALTER TABLE votacion_pokeserie
ALTER COLUMN votante_id TYPE UUID
USING votante_id::uuid;

ALTER TABLE votacion_pokefilm
ALTER COLUMN votante_id TYPE UUID
USING votante_id::uuid;


-- Connectar votante_id amb auth.users
ALTER TABLE votacion_pokeserie
ADD CONSTRAINT fk_votacion_pokeserie_user
FOREIGN KEY (votante_id)
REFERENCES auth.users(id)
ON DELETE CASCADE;

ALTER TABLE votacion_pokefilm
ADD CONSTRAINT fk_votacion_pokefilm_user
FOREIGN KEY (votante_id)
REFERENCES auth.users(id)
ON DELETE CASCADE;


-- Restricció: un vot per categoria i usuari
ALTER TABLE votacion_pokeserie
ADD CONSTRAINT unique_user_vote_pokeserie
UNIQUE (votante_id, categoria_id);

ALTER TABLE votacion_pokefilm
ADD CONSTRAINT unique_user_vote_pokefilm
UNIQUE (votante_id, categoria_id);


-- =========================================================
-- POLICIES RLS VOTACIONS
-- =========================================================

-- Inserir vot només si l'usuari és el propietari del token
CREATE POLICY "Authenticated users can vote pokeserie"
ON votacion_pokeserie
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = votante_id);

CREATE POLICY "Authenticated users can vote pokefilm"
ON votacion_pokefilm
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = votante_id);


-- Policies dummy SELECT
-- Necessàries per algunes views/PostgREST
-- però NO permeten llegir files

CREATE POLICY "No direct read pokeserie votes"
ON votacion_pokeserie
FOR SELECT
TO authenticated
USING (false);

CREATE POLICY "No direct read pokefilm votes"
ON votacion_pokefilm
FOR SELECT
TO authenticated
USING (false);


-- IMPORTANT:
-- NO crear UPDATE ni DELETE policies


-- =========================================================
-- PROTEGIR PROFILES
-- =========================================================

CREATE POLICY "Users can read own profile"
ON profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id);


-- =========================================================
-- RECREAR TRIGGER DE PROFILE
-- =========================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user;

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, role)
  VALUES (NEW.id, 'voter');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION handle_new_user();


-- =========================================================
-- FUNCTIONS SECURITY DEFINER (bypass RLS per a resultats)
-- =========================================================

CREATE OR REPLACE FUNCTION get_resultados_pokeserie()
RETURNS TABLE(categoria_id INT, pokecuento_id INT, votos BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    v.categoria_id,
    v.pokecuento_id,
    COUNT(*)::BIGINT AS votos
  FROM votacion_pokeserie v
  GROUP BY v.categoria_id, v.pokecuento_id;
END;
$$;

CREATE OR REPLACE FUNCTION get_resultados_pokefilm()
RETURNS TABLE(categoria_id INT, pokefilm_id INT, votos BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    v.categoria_id,
    v.pokefilm_id,
    COUNT(*)::BIGINT AS votos
  FROM votacion_pokefilm v
  GROUP BY v.categoria_id, v.pokefilm_id;
END;
$$;

GRANT EXECUTE ON FUNCTION get_resultados_pokeserie() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_resultados_pokefilm() TO anon, authenticated;

-- =========================================================
-- VIEWS PÚBLIQUES DE RESULTATS (basades en les functions)
-- =========================================================

CREATE OR REPLACE VIEW resultados_pokeserie AS
SELECT * FROM get_resultados_pokeserie();

CREATE OR REPLACE VIEW resultados_pokefilm AS
SELECT * FROM get_resultados_pokefilm();


-- =========================================================
-- ACCÉS PÚBLIC A RESULTATS
-- =========================================================

GRANT SELECT ON resultados_pokeserie TO anon, authenticated;
GRANT SELECT ON resultados_pokefilm TO anon, authenticated;

-- Funció que comprova si l'usuari és admin (bypasseja RLS de profiles)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$;
-- Ara les policies usen la funció en lloc de la subconsulta directa
CREATE POLICY "Admins can insert Pokecuento"
ON Pokecuento FOR INSERT TO authenticated
WITH CHECK (is_admin());
CREATE POLICY "Admins can update Pokecuento"
ON Pokecuento FOR UPDATE TO authenticated
USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "Admins can delete Pokecuento"
ON Pokecuento FOR DELETE TO authenticated
USING (is_admin());
-- Repeteix per Pokefilm, categorias_pokeserie, categorias_pokefilm, nominados_pokeserie, nominados_pokefilm

-- =========================================================
-- POKEFILM
-- =========================================================
CREATE POLICY "Admins can insert Pokefilm"
ON Pokefilm FOR INSERT TO authenticated
WITH CHECK (is_admin());
CREATE POLICY "Admins can update Pokefilm"
ON Pokefilm FOR UPDATE TO authenticated
USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "Admins can delete Pokefilm"
ON Pokefilm FOR DELETE TO authenticated
USING (is_admin());
-- =========================================================
-- CATEGORIAS_POKESERIE
-- =========================================================
CREATE POLICY "Admins can insert categorias_pokeserie"
ON categorias_pokeserie FOR INSERT TO authenticated
WITH CHECK (is_admin());
CREATE POLICY "Admins can update categorias_pokeserie"
ON categorias_pokeserie FOR UPDATE TO authenticated
USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "Admins can delete categorias_pokeserie"
ON categorias_pokeserie FOR DELETE TO authenticated
USING (is_admin());
-- =========================================================
-- CATEGORIAS_POKEFILM
-- =========================================================
CREATE POLICY "Admins can insert categorias_pokefilm"
ON categorias_pokefilm FOR INSERT TO authenticated
WITH CHECK (is_admin());
CREATE POLICY "Admins can update categorias_pokefilm"
ON categorias_pokefilm FOR UPDATE TO authenticated
USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "Admins can delete categorias_pokefilm"
ON categorias_pokefilm FOR DELETE TO authenticated
USING (is_admin());
-- =========================================================
-- NOMINADOS_POKESERIE
-- =========================================================
CREATE POLICY "Admins can insert nominados_pokeserie"
ON nominados_pokeserie FOR INSERT TO authenticated
WITH CHECK (is_admin());
CREATE POLICY "Admins can delete nominados_pokeserie"
ON nominados_pokeserie FOR DELETE TO authenticated
USING (is_admin());
-- =========================================================
-- NOMINADOS_POKEFILM
-- =========================================================
CREATE POLICY "Admins can insert nominados_pokefilm"
ON nominados_pokefilm FOR INSERT TO authenticated
WITH CHECK (is_admin());
CREATE POLICY "Admins can delete nominados_pokefilm"
ON nominados_pokefilm FOR DELETE TO authenticated
USING (is_admin());

--//////////////////////////////////////////////////////////////////////////////////
-- 1. Functions SECURITY DEFINER
CREATE OR REPLACE FUNCTION get_resultados_pokeserie()
RETURNS TABLE(categoria_id INT, pokecuento_id INT, votos BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
RETURN QUERY
SELECT v.categoria_id, v.pokecuento_id, COUNT(*)::BIGINT
FROM votacion_pokeserie v
GROUP BY v.categoria_id, v.pokecuento_id;
END;
$$;

CREATE OR REPLACE FUNCTION get_resultados_pokefilm()
RETURNS TABLE(categoria_id INT, pokefilm_id INT, votos BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
RETURN QUERY
SELECT v.categoria_id, v.pokefilm_id, COUNT(*)::BIGINT
FROM votacion_pokefilm v
GROUP BY v.categoria_id, v.pokefilm_id;
END;
$$;

GRANT EXECUTE ON FUNCTION get_resultados_pokeserie() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_resultados_pokefilm() TO anon, authenticated;

-- 2. DROP + CREATE (no es pot canviar l'estructura amb REPLACE)
DROP VIEW IF EXISTS resultados_pokeserie;
CREATE VIEW resultados_pokeserie AS
SELECT * FROM get_resultados_pokeserie();

DROP VIEW IF EXISTS resultados_pokefilm;
CREATE VIEW resultados_pokefilm AS
SELECT * FROM get_resultados_pokefilm();

GRANT SELECT ON resultados_pokeserie TO anon, authenticated;
GRANT SELECT ON resultados_pokefilm TO anon, authenticated;