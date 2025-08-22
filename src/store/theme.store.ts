import {create} from "zustand"

type Theme = "light" | "dark" | "system"
interface ThemeState { theme: Theme; setTheme: (t: Theme)=>void }

export const useThemeStore = create<ThemeState>((set: (partial: Partial<ThemeState>) => void) => ({
  theme: "system",
  setTheme: (t: Theme) => set({theme: t})
}))
