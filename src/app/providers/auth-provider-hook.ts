import * as React from "react"
import type {Session, User} from "@supabase/supabase-js";

interface AuthContextValue {
    session: Session | null
    user: User | null
    loading: boolean
}

export const AuthContext = React.createContext<AuthContextValue | null>(null)

export function useAuth() {
    const ctx = React.useContext(AuthContext)
    if (!ctx) throw new Error("useAuth must be used within <AuthProvider>")
    return ctx
}
