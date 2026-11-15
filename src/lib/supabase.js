import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
// Acceptem tant la clau anon tradicional com la nova publishable key.
const supabaseKey =
  import.meta.env.VITE_SUPABASE_ANON_KEY ||
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

if (!supabaseUrl || !supabaseKey) {
  throw new Error(
    'Falten VITE_SUPABASE_URL i VITE_SUPABASE_ANON_KEY (o VITE_SUPABASE_PUBLISHABLE_KEY). Revisa el fitxer .env o les variables del build.'
  )
}

export const supabase = createClient(supabaseUrl, supabaseKey)