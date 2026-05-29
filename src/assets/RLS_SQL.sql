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
-- VIEWS PÚBLIQUES DE RESULTATS
-- =========================================================

CREATE OR REPLACE VIEW resultados_pokeserie AS
SELECT
  categoria_id,
  pokecuento_id,
  COUNT(*) AS votos
FROM votacion_pokeserie
GROUP BY categoria_id, pokecuento_id;

CREATE OR REPLACE VIEW resultados_pokefilm AS
SELECT
  categoria_id,
  pokefilm_id,
  COUNT(*) AS votos
FROM votacion_pokefilm
GROUP BY categoria_id, pokefilm_id;


-- =========================================================
-- ACCÉS PÚBLIC A RESULTATS
-- =========================================================

GRANT SELECT ON resultados_pokeserie TO anon, authenticated;
GRANT SELECT ON resultados_pokefilm TO anon, authenticated;