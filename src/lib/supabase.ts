import {createClient} from "@supabase/supabase-js"
import {AuthStorage, authStorage} from "@/lib/auth_storage.ts";

const url = import.meta.env.VITE_SUPABASE_URL as string
const key = import.meta.env.VITE_SUPABASE_ANON_KEY as string

export const supabase = createClient(url, key, {
    auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
        storage: authStorage as AuthStorage,
    },
})
