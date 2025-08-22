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
