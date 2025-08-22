#!/usr/bin/env bash
set -euo pipefail

# --- directories ---
mkdir -p \
  public \
  src/app/{providers,layout} \
  src/styles \
  src/components/{ui,primitives,data-display,form,feedback} \
  src/features/{auth/{components,api,hooks,pages},dashboard/{components,pages}} \
  src/lib \
  src/hooks \
  src/store \
  src/assets/{images,icons,fonts} \
  src/config \
  src/types \
  src/test \
  e2e \
  .github/workflows

# --- files ---

# Root configs (created if missing; safe to overwrite if you want)
cat > tailwind.config.ts <<'EOF'
import type { Config } from "tailwindcss"
import { fontFamily } from "tailwindcss/defaultTheme"

export default {
  darkMode: ["class"],
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      fontFamily: {
        sans: ["Inter", ...fontFamily.sans],
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config
EOF

cat > postcss.config.cjs <<'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
EOF

cat > shadcn.json <<'EOF'
{
  "$schema": "https://shadcn.com/schema.json",
  "style": "default",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "src/styles/globals.css",
    "baseColor": "slate",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib"
  }
}
EOF

cat > tsconfig.paths.json <<'EOF'
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@/app/*": ["src/app/*"],
      "@/components/*": ["src/components/*"],
      "@/features/*": ["src/features/*"],
      "@/styles/*": ["src/styles/*"],
      "@/lib/*": ["src/lib/*"],
      "@/config/*": ["src/config/*"],
      "@/types/*": ["src/types/*"]
    }
  }
}
EOF

cat > .eslintrc.cjs <<'EOF'
/* basic react-ts eslint config; tweak as needed */
module.exports = {
  root: true,
  parser: "@typescript-eslint/parser",
  plugins: ["@typescript-eslint", "react", "react-hooks"],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended"
  ],
  settings: { react: { version: "detect" } }
};
EOF

cat > .prettierrc <<'EOF'
{
  "singleQuote": false,
  "semi": true,
  "trailingComma": "es5",
  "printWidth": 100
}
EOF

cat > .env.example <<'EOF'
# public vars: prefix with VITE_
VITE_API_BASE_URL=https://api.example.com
EOF

cat > .github/workflows/ci.yml <<'EOF'
name: CI
on:
  push:
    branches: [ main, develop, "**/**" ]
  pull_request:
    branches: [ main ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: 9 }
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm typecheck || echo "typecheck step optional"
      - run: pnpm -s -w -r build || pnpm -s build
      - run: pnpm -s lint || echo "lint step optional"
      - run: pnpm -s test || echo "no tests yet"
EOF

# --- styles ---
cat > src/styles/globals.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root { --radius: 0.75rem; }
  html, body, #root { height: 100%; }
}
EOF

cat > src/styles/themes.css <<'EOF'
/* Example theme tokens that shadcn components can inherit */
:root {
  --radius: 0.75rem;
}
.light {}
.dark {}
EOF

# --- lib ---
cat > src/lib/cn.ts <<'EOF'
import { clsx } from "clsx"
import { twMerge } from "tailwind-merge"
export function cn(...inputs: Parameters<typeof clsx>) {
  return twMerge(clsx(inputs))
}
EOF

cat > src/lib/utils.ts <<'EOF'
export const sleep = (ms: number) => new Promise((res) => setTimeout(res, ms));
EOF

# --- hooks ---
cat > src/hooks/useMediaQuery.ts <<'EOF'
import * as React from "react"
export function useMediaQuery(query: string) {
  const [matches, setMatches] = React.useState<boolean>(() => globalThis?.window?.matchMedia?.(query).matches ?? false)
  React.useEffect(() => {
    const m = window.matchMedia(query)
    const onChange = () => setMatches(m.matches)
    onChange(); m.addEventListener("change", onChange)
    return () => m.removeEventListener("change", onChange)
  }, [query])
  return matches
}
EOF

# --- app ---
cat > src/app/providers/theme-provider.tsx <<'EOF'
import * as React from "react"
type Theme = "light" | "dark" | "system"
const Ctx = React.createContext<{theme: Theme; setTheme: (t: Theme)=>void} | null>(null)
export function useTheme() {
  const ctx = React.useContext(Ctx)
  if (!ctx) throw new Error("useTheme must be used within ThemeProvider")
  return ctx
}
export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = React.useState<Theme>(() => (localStorage.getItem("theme") as Theme) || "system")
  React.useEffect(() => {
    const root = document.documentElement
    const resolved = theme === "system"
      ? (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
      : theme
    root.classList.remove("light","dark"); root.classList.add(resolved)
    localStorage.setItem("theme", theme)
  }, [theme])
  return <Ctx.Provider value={{ theme, setTheme }}>{children}</Ctx.Provider>
}
EOF

cat > src/app/layout/AppLayout.tsx <<'EOF'
import * as React from "react"
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
EOF

cat > src/app/router.tsx <<'EOF'
import { createBrowserRouter } from "react-router-dom"
import AppLayout from "@/app/layout/AppLayout"
import { LoginPage } from "@/features/auth/pages/LoginPage"
import { DashboardPage } from "@/features/dashboard/pages/DashboardPage"

export const router = createBrowserRouter([
  {
    path: "/",
    element: <AppLayout />,
    children: [
      { index: true, element: <DashboardPage /> },
      { path: "login", element: <LoginPage /> }
    ]
  }
])
EOF

cat > src/app/main.tsx <<'EOF'
import React from "react"
import ReactDOM from "react-dom/client"
import { RouterProvider } from "react-router-dom"
import "@/styles/globals.css"
import "@/styles/themes.css"
import { router } from "./router"
import { ThemeProvider } from "./providers/theme-provider"

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ThemeProvider>
      <RouterProvider router={router} />
    </ThemeProvider>
  </React.StrictMode>
)
EOF

# --- components ---
# Keep components/ui for shadcn-generated files; add a sample primitive wrapper:
cat > src/components/primitives/Button.tsx <<'EOF'
import * as React from "react"
import { cn } from "@/lib/cn"

/** Simple brand button; swap with shadcn/ui Button when you generate it */
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "default" | "outline"
}
export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = "default", ...props }, ref) => (
    <button
      ref={ref}
      className={cn(
        "inline-flex items-center justify-center rounded-md px-3 py-2 text-sm font-medium transition-colors",
        variant === "default" && "bg-black text-white hover:bg-black/90 dark:bg-white dark:text-black dark:hover:bg-white/90",
        variant === "outline" && "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
        className
      )}
      {...props}
    />
  )
)
Button.displayName = "Button"
EOF

# --- features: auth ---
cat > src/features/auth/pages/LoginPage.tsx <<'EOF'
import * as React from "react"
import { Button } from "@/components/primitives/Button"

export function LoginPage() {
  return (
    <div className="mx-auto max-w-sm space-y-4">
      <h1 className="text-xl font-semibold">Login</h1>
      <div className="space-y-2">
        <input className="w-full rounded-md border px-3 py-2" placeholder="Email" />
        <input className="w-full rounded-md border px-3 py-2" placeholder="Password" type="password" />
      </div>
      <Button className="w-full">Sign in</Button>
    </div>
  )
}
EOF

cat > src/features/auth/api/index.ts <<'EOF'
export async function login(email: string, password: string) {
  // TODO: wire to real API
  await new Promise((r)=>setTimeout(r, 400))
  return { token: "demo", user: { email } }
}
EOF

cat > src/features/auth/hooks/useLogin.ts <<'EOF'
import * as React from "react"
import { login } from "../api"
export function useLogin(){
  const [loading, setLoading] = React.useState(false)
  const [error, setError] = React.useState<string | null>(null)
  const run = async (email:string, password:string) => {
    setLoading(true); setError(null)
    try { return await login(email, password) }
    catch (e:any){ setError(e?.message ?? "Login failed") }
    finally { setLoading(false) }
  }
  return { run, loading, error }
}
EOF

cat > src/features/auth/index.ts <<'EOF'
export * from "./pages/LoginPage"
EOF

# --- features: dashboard ---
cat > src/features/dashboard/pages/DashboardPage.tsx <<'EOF'
import * as React from "react"
export function DashboardPage() {
  return (
    <section className="space-y-4">
      <h1 className="text-2xl font-semibold">Dashboard</h1>
      <p className="text-muted-foreground">Welcome to 32-ways ✨</p>
    </section>
  )
}
EOF

cat > src/features/dashboard/index.ts <<'EOF'
export * from "./pages/DashboardPage"
EOF

# --- store ---
cat > src/store/theme.store.ts <<'EOF'
import { create } from "zustand"
type Theme = "light" | "dark" | "system"
interface ThemeState { theme: Theme; setTheme: (t: Theme)=>void }
export const useThemeStore = create<ThemeState>((set) => ({
  theme: "system",
  setTheme: (t) => set({ theme: t })
}))
EOF

# --- config / types ---
cat > src/config/constants.ts <<'EOF'
export const APP_NAME = "32-ways"
EOF

cat > src/config/env.ts <<'EOF'
export const ENV = {
  API_BASE_URL: import.meta.env.VITE_API_BASE_URL || ""
}
EOF

cat > src/types/global.d.ts <<'EOF'
// Put global ambient types here
EOF

# --- placeholders to keep folders in git ---
touch src/components/ui/.gitkeep src/components/data-display/.gitkeep src/components/form/.gitkeep src/components/feedback/.gitkeep
touch src/features/auth/components/.gitkeep src/features/dashboard/components/.gitkeep
touch src/assets/images/.gitkeep src/assets/icons/.gitkeep src/assets/fonts/.gitkeep
touch src/test/.gitkeep e2e/.gitkeep

echo "✅ Scaffold complete."
