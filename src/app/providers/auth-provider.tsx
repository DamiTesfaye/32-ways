import * as React from "react"
import type {Session} from "@supabase/supabase-js"
import {supabase} from "@/lib/supabase"
import {AuthContext} from "./auth-provider-hook"

export function AuthProvider({children}: { children: React.ReactNode }) {
    const [session, setSession] = React.useState<Session | null>(null)
    const [loading, setLoading] = React.useState(true)

    React.useEffect(() => {
        let mounted = true
        supabase.auth.getSession().then(({data}) => {
            if (!mounted) return
            setSession(data.session ?? null)
            setLoading(false)
        })

        const {data} = supabase.auth.onAuthStateChange((_event, newSession) => {
            setSession(newSession)
            setLoading(false)
        })

        return () => {
            mounted = false
            data.subscription.unsubscribe()
        }
    }, [])

    const value = React.useMemo(
        () => ({session, user: session?.user ?? null, loading}),
        [session, loading]
    )

    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}