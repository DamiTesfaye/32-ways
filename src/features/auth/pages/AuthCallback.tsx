import {useEffect} from "react"
import {useLocation, useNavigate} from "react-router-dom"
import {supabase} from "@/lib/supabase"

export default function AuthCallback() {
    const nav = useNavigate()
    const loc = useLocation()

    useEffect(() => {
        let mounted = true
        ;(async () => {
            try {
                if (typeof supabase.auth.exchangeCodeForSession === "function") {
                    const input = loc.search || loc.hash || window.location.href
                    await supabase.auth.exchangeCodeForSession(input)
                }
            } catch (e) {
                console.error("exchangeCodeForSession failed", e)
            }

            const {data} = await supabase.auth.getSession()
            const params = new URLSearchParams(
                (loc.search && loc.search) || (loc.hash ? loc.hash.replace(/^#/, "?") : "")
            )
            const next = params.get("next") || "/dashboard"

            if (!mounted) return
            nav(data.session ? next : "/login", {replace: true})
        })()

        return () => {
            mounted = false
        }
    }, [loc, nav])

    return (
        <div className="grid min-h-dvh place-items-center">
            <div className="text-sm text-muted-foreground">Finishing sign-in…</div>
        </div>
    )
}
