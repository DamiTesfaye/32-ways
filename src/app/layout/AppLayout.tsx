import {Link, NavLink, Outlet} from "react-router-dom"
import {useAuth} from "@/app/providers/auth-provider"
import {Button} from "@/components/ui/button"
import {UserMenu} from "@/components/app/UserMenu"

export default function AppLayout() {
  const {user} = useAuth()

  return (
    <div className="min-h-dvh bg-background text-foreground">
      <header className="border-b">
        <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
          <div className="flex items-center gap-6">
            <Link to="/" className="font-semibold">32-ways</Link>
            <nav className="hidden gap-4 sm:flex">
              <NavLink to="/dashboard"
                       className={({isActive}) => isActive ? "text-foreground" : "text-muted-foreground hover:text-foreground"}>Dashboard</NavLink>
              <NavLink to="/profile"
                       className={({isActive}) => isActive ? "text-foreground" : "text-muted-foreground hover:text-foreground"}>Profile</NavLink>
            </nav>
          </div>
          <div className="flex items-center gap-2">
            {user ? (
                <UserMenu/>
            ) : (
                <Button asChild variant="outline" size="sm"><Link to="/login">Sign in</Link></Button>
            )}
          </div>
        </div>
      </header>
      <main className="mx-auto max-w-6xl px-4 py-6"><Outlet/></main>
    </div>
  )
}
