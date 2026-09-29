/// Proyecto de Supabase donde viven los casos publicados y los borradores.
///
/// La clave publicable es pública por diseño: va en el navegador de cualquier
/// visitante. Lo que protege los datos son las reglas de acceso (RLS) de
/// `supabase/migrations/`, no el secreto de esta clave.
const String supabaseUrl = 'https://lwghxewjnxeklsdjjxxu.supabase.co';

const String supabasePublishableKey =
    'sb_publishable_4-AQLkxoTvqcMFUMsg7r-Q_Xx6yi1lD';

/// Límite común para las lecturas REST de Supabase en el cliente web.
const Duration kSupabaseNetworkTimeout = Duration(seconds: 15);
