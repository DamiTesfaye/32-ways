import { Outlet, Link } from "react-router-dom"
import { useTheme } from "../providers/theme-provider"

export default function AppLayout() {
  const { theme, setTheme } = useTheme()
  return (
    <div className="min-h-dvh bg-background text-foreground">
      <header className="border-b">
        <div className="mx-auto max-w-6xl px-4 h-14 flex items-center justify-between">
          <nav className="flex items-center gap-4">
            <Link to="/" className="font-semibold">Home</Link>
            <Link to="/login" className="text-sm opacity-80 hover:opacity-100">Login</Link>
          </nav>
          <button
            className="rounded-md px-3 py-1 border"
            onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
          >
            Toggle {theme === "dark" ? "Light" : "Dark"}
          </button>
        </div>
      </header>
      <main className="mx-auto max-w-6xl px-4 py-6">
        <Outlet />
      </main>
    </div>
  )
}
