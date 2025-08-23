import {Navigate, Outlet, useLocation} from "react-router-dom"
import {useAuth} from "@/app/providers/auth-provider"

export default function ProtectedRoute() {
    const {user, loading} = useAuth()
    const location = useLocation()

    if (loading) {
        return (
            <div className="grid min-h-[40vh] place-items-center">
                <div className="h-6 w-6 animate-spin rounded-full border border-muted-foreground border-t-transparent"/>
            </div>
        )
    }

    if (!user) {
        return <Navigate to="/login" replace state={{from: location.pathname}}/>
    }

    return <Outlet/>
}
