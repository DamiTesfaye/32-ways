export type StorageMode = "local" | "session" | "memory"

type Backend = {
    getItem(key: string): string | null
    setItem(key: string, value: string): void
    removeItem(key: string): void
}

const memory = new Map<string, string>()
const memoryBackend: Backend = {
    getItem: (k) => (memory.has(k) ? memory.get(k)! : null),
    setItem: (k, v) => void memory.set(k, v),
    removeItem: (k) => void memory.delete(k),
}

function getBackend(mode: StorageMode): Backend {
    if (mode === "local") return localStorage
    if (mode === "session") return sessionStorage
    return memoryBackend
}

export function purgeSupabaseTokens() {
    try {
        const keys: string[] = []
        for (let i = 0; i < localStorage.length; i++) {
            const k = localStorage.key(i)!
            if (k.startsWith("sb-") && k.endsWith("-auth-token")) keys.push(k)
        }
        keys.forEach((k) => localStorage.removeItem(k))
    } catch (e) {
        console.error("Failed to purge Supabase tokens from local storage.", e)
    }
}

let mode: StorageMode =
    (localStorage.getItem("sb-remember-mode") as StorageMode) || "local"

export type AuthStorage = Backend & { setMode: (m: StorageMode) => void; getMode: () => StorageMode }

export const authStorage: AuthStorage = {
    getItem: (key) => getBackend(mode).getItem(key),
    setItem: (key, value) => getBackend(mode).setItem(key, value),
    removeItem: (key) => getBackend(mode).removeItem(key),
    setMode: (m) => {
        mode = m
        // Persist the preference for next visits
        localStorage.setItem("sb-remember-mode", m)
    },
    getMode: () => mode,
}
