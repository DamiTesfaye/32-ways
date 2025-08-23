#!/usr/bin/env bash
set -euo pipefail

###
# Apply Supabase auth flow + UI to the project
# - Creates/updates files for: client, providers, routes, pages, UserMenu
# - Installs deps and shadcn/ui components
# - Backs up router.tsx and main.tsx if they exist
#
# Usage:
#   chmod +x scripts/apply-auth-scaffold.sh
#   ./scripts/apply-auth-scaffold.sh
#
# Optional: CREATE_EDGE_FUNCTIONS=1 ./scripts/apply-auth-scaffold.sh
#   (adds Supabase Edge Functions for password policy + server-side enforcement)
###

ROOT_DIR="$(pwd)"
echo "\n▶ Applying auth scaffold in: $ROOT_DIR\n"

if ! command -v pnpm >/dev/null 2>&1; then
  echo "❌ pnpm is required. Install it first: https://pnpm.io/installation" >&2
  exit 1
fi

CREATE_EDGE_FUNCTIONS="${CREATE_EDGE_FUNCTIONS:-0}"

# --- Directories ---
mkdir -p \
  src/lib \
  src/app/{providers,routes,layout} \
  src/features/auth/pages \
  src/features/profile/pages \
  src/components/app \
  supabase/functions || true

# --- Files ---

# src/lib/supabase.ts
cat > src/lib/supabase.ts <<'EOF'
import { createClient } from "@supabase/supabase-js"

const url = import.meta.env.VITE_SUPABASE_URL as string
const key = import.meta.env.VITE_SUPABASE_ANON_KEY as string

export const supabase = createClient(url, key, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
})
EOF

# src/app/providers/auth-provider.tsx
cat > src/app/providers/auth-provider.tsx <<'EOF'
import * as React from "react"
import type { Session, User } from "@supabase/supabase-js"
import { supabase } from "@/lib/supabase"

interface AuthContextValue {
  session: Session | null
  user: User | null
  loading: boolean
}

const AuthContext = React.createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = React.useState<Session | null>(null)
  const [loading, setLoading] = React.useState(true)

  React.useEffect(() => {
    let mounted = true
    supabase.auth.getSession().then(({ data }) => {
      if (!mounted) return
      setSession(data.session ?? null)
      setLoading(false)
    })

    const { data } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession)
      setLoading(false)
    })

    return () => {
      mounted = false
      data.subscription.unsubscribe()
    }
  }, [])

  const value = React.useMemo(
    () => ({ session, user: session?.user ?? null, loading }),
    [session, loading]
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = React.useContext(AuthContext)
  if (!ctx) throw new Error("useAuth must be used within <AuthProvider>")
  return ctx
}
EOF

# src/app/routes/ProtectedRoute.tsx
cat > src/app/routes/ProtectedRoute.tsx <<'EOF'
import * as React from "react"
import { Outlet, Navigate, useLocation } from "react-router-dom"
import { useAuth } from "@/app/providers/auth-provider"

export default function ProtectedRoute() {
  const { user, loading } = useAuth()
  const location = useLocation()

  if (loading) {
    return (
      <div className="grid min-h-[40vh] place-items-center">
        <div className="h-6 w-6 animate-spin rounded-full border border-muted-foreground border-t-transparent" />
      </div>
    )
  }

  if (!user) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />
  }

  return <Outlet />
}
EOF

# src/features/auth/pages/AuthCallback.tsx
cat > src/features/auth/pages/AuthCallback.tsx <<'EOF'
import * as React from "react"
import { useEffect } from "react"
import { useLocation, useNavigate } from "react-router-dom"
import { supabase } from "@/lib/supabase"

export default function AuthCallback() {
  const nav = useNavigate()
  const loc = useLocation()

  useEffect(() => {
    let mounted = true
    ;(async () => {
      try {
        // Some supabase-js versions expose exchangeCodeForSession; try it if present.
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        if (typeof supabase.auth.exchangeCodeForSession === "function") {
          const input = loc.search || loc.hash || window.location.href
          // @ts-ignore
          await supabase.auth.exchangeCodeForSession(input)
        }
      } catch {}

      const { data } = await supabase.auth.getSession()
      const params = new URLSearchParams(
        (loc.search && loc.search) || (loc.hash ? loc.hash.replace(/^#/, "?") : "")
      )
      const next = params.get("next") || "/dashboard"

      if (!mounted) return
      nav(data.session ? next : "/login", { replace: true })
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
EOF

# src/features/auth/pages/LoginPage.tsx (complete regenerated page)
cat > src/features/auth/pages/LoginPage.tsx <<'EOF'
import * as React from "react"
import { Apple, Eye, EyeOff, Lock, Mail, Loader2 } from "lucide-react"
import { useForm } from "react-hook-form"
import { z } from "zod"
import { zodResolver } from "@hookform/resolvers/zod"
import { useLocation, useNavigate } from "react-router-dom"
import { supabase } from "@/lib/supabase"

// shadcn/ui
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Separator } from "@/components/ui/separator"
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import { Checkbox } from "@/components/ui/checkbox"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"

const LoginSchema = z.object({
  email: z.string({ required_error: "Email is required" }).min(1, "Email is required").email("Enter a valid email"),
  password: z.string({ required_error: "Password is required" }).min(6, "Password must be at least 6 characters"),
  remember: z.boolean().default(true),
})

type LoginValues = z.infer<typeof LoginSchema>

const ResetSchema = z.object({
  email: z.string({ required_error: "Email is required" }).min(1, "Email is required").email("Enter a valid email"),
})

type ResetValues = z.infer<typeof ResetSchema>

function friendlyErrorMessage(msg?: string) {
  const m = (msg || "").toLowerCase()
  if (m.includes("rate") && (m.includes("limit") || m.includes("too many") || m.includes("requests"))) {
    return "Too many attempts right now. Please wait about a minute and try again."
  }
  if (m.includes("invalid email or password") || m.includes("invalid login")) {
    return "Invalid email or password"
  }
  if (m.includes("email not confirmed")) {
    return "Email not confirmed. Check your inbox."
  }
  if (m.includes("expired") || m.includes("invalid")) {
    return "This link is invalid or has expired. Request a new one."
  }
  return msg || "Something went wrong. Please try again."
}

function clearSupabasePersistence() {
  try {
    const anyClient = supabase as any
    const storageKey: string | undefined = anyClient?.auth?.storageKey
    if (storageKey) localStorage.removeItem(storageKey)
    const toDelete: string[] = []
    for (let i = 0; i < localStorage.length; i++) {
      const k = localStorage.key(i)!
      if (k.startsWith("sb-") && k.includes("auth-token")) toDelete.push(k)
    }
    toDelete.forEach((k) => localStorage.removeItem(k))
  } catch {}
}

export default function LoginPage() {
  const nav = useNavigate()
  const loc = useLocation() as any
  const from = loc?.state?.from || "/dashboard"

  const [showPassword, setShowPassword] = React.useState(false)
  const [oauthError, setOauthError] = React.useState<string | null>(null)
  const [resetOpen, setResetOpen] = React.useState(false)
  const [resetInfo, setResetInfo] = React.useState<string | null>(null)

  const form = useForm<LoginValues>({ resolver: zodResolver(LoginSchema), defaultValues: { email: "", password: "", remember: true }, mode: "onBlur" })
  const resetForm = useForm<ResetValues>({ resolver: zodResolver(ResetSchema), defaultValues: { email: "" }, mode: "onBlur" })

  async function onSubmit(values: LoginValues) {
    setOauthError(null)
    // @ts-expect-error - root used via setError
    form.clearErrors?.("root")

    const { error } = await supabase.auth.signInWithPassword({ email: values.email, password: values.password })

    if (error) {
      const msg = friendlyErrorMessage(error.message)
      if (/email/i.test(msg)) form.setError("email", { message: msg })
      else if (/password/i.test(msg)) form.setError("password", { message: msg })
      else form.setError("root" as any, { message: msg })
      return
    }

    if (!values.remember) clearSupabasePersistence()
    nav(from, { replace: true })
  }

  async function handleOAuth(provider: "google" | "apple") {
    setOauthError(null)
    try {
      const redirect = `${window.location.origin}/auth/callback?next=${encodeURIComponent(from)}`
      const { error } = await supabase.auth.signInWithOAuth({ provider, options: { redirectTo: redirect } })
      if (error) throw error
    } catch (e: any) {
      setOauthError(friendlyErrorMessage(e?.message))
    }
  }

  async function onSendReset(values: ResetValues) {
    setResetInfo(null)
    try {
      const redirectTo = `${window.location.origin}/auth/reset-password`
      const { error } = await supabase.auth.resetPasswordForEmail(values.email, { redirectTo })
      if (error) throw error
      setResetInfo("If an account exists for that email, a reset link has been sent.")
    } catch (e: any) {
      resetForm.setError("email", { message: friendlyErrorMessage(e?.message) })
    }
  }

  return (
    <div className="min-h-dvh w-full bg-muted/30 py-8 md:py-12 lg:py-16 transition-colors">
      <div className="mx-auto max-w-6xl px-3 sm:px-6">
        <div className="grid gap-6 rounded-2xl border bg-background shadow-sm ring-1 ring-border/40 lg:grid-cols-2 lg:gap-0">
          <aside className="relative hidden overflow-hidden rounded-t-2xl lg:block lg:rounded-l-2xl lg:rounded-tr-none">
            <div className="absolute inset-0 bg-gradient-to-b from-transparent to-black/10 dark:to-white/10" />
            <img src="https://images.unsplash.com/photo-1631195510001-5f3c781b1f2f?q=80&w=1200&auto=format&fit=crop" alt="Playful machine illustration" className="h-full w-full object-cover" loading="lazy" />
          </aside>

          <section className="flex items-center justify-center px-4 py-8 sm:px-8 sm:py-10 lg:p-12">
            <div className="w-full max-w-md">
              <div className="mb-8 hidden items-center justify-end text-xs text-muted-foreground lg:flex">
                <span className="mr-1">Don't have an account?</span>
                <a href="#" className="font-medium text-foreground underline-offset-4 hover:underline">Sign up</a>
              </div>

              <h1 className="text-2xl font-semibold tracking-tight sm:text-3xl">Sign in</h1>
              <p className="mt-2 text-sm text-muted-foreground">Sign in with your account</p>

              <div className="mt-4 flex flex-col gap-3 sm:flex-row">
                <Button variant="outline" className="w-full justify-center gap-2 shadow-sm hover:shadow transition-shadow" type="button" onClick={() => handleOAuth("google")} aria-label="Continue with Google">
                  <svg viewBox="0 0 24 24" aria-hidden="true" className="h-4 w-4"><path fill="#EA4335" d="M12 10.2v3.9h5.4c-.2 1.3-1.6 3.7-5.4 3.7-3.3 0-6-2.7-6-6s2.7-6 6-6c1.9 0 3.2.8 3.9 1.5l2.6-2.5C16.9 3 14.7 2 12 2 6.9 2 2.8 6.1 2.8 11.2S6.9 20.4 12 20.4c6.9 0 9.5-4.8 8.9-9.1H12z"/></svg>
                  Google
                </Button>
                <Button variant="outline" className="w-full justify-center gap-2 shadow-sm hover:shadow transition-shadow" type="button" onClick={() => handleOAuth("apple")} aria-label="Continue with Apple">
                  <Apple className="h-4 w-4" />
                  Apple ID
                </Button>
              </div>
              {oauthError && (<p role="alert" className="mt-2 text-xs text-destructive">{oauthError}</p>)}

              <div className="my-6">
                <div className="flex items-center gap-3 text-xs text-muted-foreground">
                  <Separator className="flex-1" />
                  <span>Or continue with email address</span>
                  <Separator className="flex-1" />
                </div>
              </div>

              <Form {...form}>
                <form onSubmit={form.handleSubmit(onSubmit)} noValidate className="space-y-4">
                  <FormField control={form.control} name="email" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Email address</FormLabel>
                      <FormControl>
                        <div className="relative">
                          <Mail className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                          <Input type="email" placeholder="tami@uilt.net" className="pl-9" {...field} />
                        </div>
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )} />

                  <FormField control={form.control} name="password" render={({ field }) => (
                    <FormItem>
                      <div className="flex items-center justify-between">
                        <FormLabel>Password</FormLabel>
                        <Dialog open={resetOpen} onOpenChange={setResetOpen}>
                          <DialogTrigger asChild>
                            <button className="text-xs text-muted-foreground underline-offset-4 hover:underline" type="button">Forgot password?</button>
                          </DialogTrigger>
                          <DialogContent className="sm:max-w-md">
                            <DialogHeader>
                              <DialogTitle>Reset password</DialogTitle>
                              <DialogDescription>Enter your email and we'll send you a reset link.</DialogDescription>
                            </DialogHeader>
                            <Form {...resetForm}>
                              <form onSubmit={resetForm.handleSubmit(onSendReset)} className="space-y-3">
                                <FormField control={resetForm.control} name="email" render={({ field }) => (
                                  <FormItem>
                                    <FormLabel>Email</FormLabel>
                                    <FormControl><Input type="email" placeholder="you@example.com" {...field} /></FormControl>
                                    <FormMessage />
                                  </FormItem>
                                )} />
                                {resetInfo && (<p className="text-xs text-muted-foreground">{resetInfo}</p>)}
                                <DialogFooter>
                                  <Button type="submit" className="w-full sm:w-auto" disabled={resetForm.formState.isSubmitting}>Send reset link</Button>
                                </DialogFooter>
                              </form>
                            </Form>
                          </DialogContent>
                        </Dialog>
                      </div>
                      <FormControl>
                        <div className="relative">
                          <Lock className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                          <Input type={showPassword ? "text" : "password"} placeholder="••••••••" className="pl-9 pr-10" {...field} />
                          <button type="button" aria-label={showPassword ? "Hide password" : "Show password"} className="absolute right-2 top-1/2 -translate-y-1/2 rounded-md p-2 text-muted-foreground hover:bg-accent hover:text-accent-foreground" onClick={() => setShowPassword((s) => !s)}>
                            {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                          </button>
                        </div>
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )} />

                  <FormField control={form.control} name="remember" render={({ field }) => (
                    <FormItem className="flex items-center space-x-2">
                      <FormControl><input type="checkbox" className="peer sr-only" checked={field.value} onChange={(e) => field.onChange(e.target.checked)} /></FormControl>
                      <FormLabel className="!mt-0 select-none cursor-pointer before:mr-2 before:inline-block before:h-4 before:w-4 before:rounded before:border before:align-middle before:content-[''] peer-checked:before:bg-primary before:border-input">Remember me</FormLabel>
                    </FormItem>
                  )} />

                  {/* @ts-expect-error - root is allowed when setError used */}
                  {form.formState.errors.root?.message && (
                    // @ts-ignore
                    <p role="alert" className="text-xs text-destructive">{form.formState.errors.root.message}</p>
                  )}

                  <Button type="submit" className="w-full" disabled={form.formState.isSubmitting}>
                    {form.formState.isSubmitting ? (<><Loader2 className="mr-2 h-4 w-4 animate-spin" /> Signing in…</>) : (<>Start trading</>)}
                  </Button>
                </form>
              </Form>

              <p className="mt-6 text-center text-xs text-muted-foreground lg:hidden">
                Don't have an account? <a href="#" className="font-medium text-foreground underline-offset-4 hover:underline">Sign up</a>
              </p>
            </div>
          </section>
        </div>
      </div>
    </div>
  )
}
EOF

# src/components/app/UserMenu.tsx
cat > src/components/app/UserMenu.tsx <<'EOF'
import * as React from "react"
import { useNavigate } from "react-router-dom"
import { LogOut, User as UserIcon } from "lucide-react"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Button } from "@/components/ui/button"
import { useAuth } from "@/app/providers/auth-provider"
import { supabase } from "@/lib/supabase"

function initialFromEmail(email?: string | null) { return email ? email.charAt(0).toUpperCase() : "?" }

export function UserMenu() {
  const { user } = useAuth()
  const navigate = useNavigate()

  const email = user?.email ?? (user?.user_metadata as any)?.email
  const name = (user?.user_metadata as any)?.full_name as string | undefined
  const avatarUrl = (user?.user_metadata as any)?.avatar_url as string | undefined

  async function signOut() { await supabase.auth.signOut(); navigate("/login", { replace: true }) }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" className="h-9 w-9 rounded-full p-0" aria-label="User menu">
          <Avatar className="h-9 w-9">
            <AvatarImage src={avatarUrl} alt={name ?? email ?? "User"} />
            <AvatarFallback>{initialFromEmail(email)}</AvatarFallback>
          </Avatar>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-56">
        <DropdownMenuLabel className="truncate">
          <div className="text-sm font-medium leading-tight truncate">{name ?? email ?? "Account"}</div>
          {email && name && (<div className="text-xs text-muted-foreground truncate">{email}</div>)}
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem onSelect={() => navigate("/profile")}><UserIcon className="mr-2 h-4 w-4" /> Profile</DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem className="text-destructive focus:text-destructive" onSelect={signOut}><LogOut className="mr-2 h-4 w-4" /> Sign out</DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
EOF

# src/app/layout/AppLayout.tsx (header with UserMenu)
cat > src/app/layout/AppLayout.tsx <<'EOF'
import * as React from "react"
import { Link, NavLink, Outlet } from "react-router-dom"
import { useAuth } from "@/app/providers/auth-provider"
import { Button } from "@/components/ui/button"
import { UserMenu } from "@/components/app/UserMenu"

export default function AppLayout() {
  const { user } = useAuth()

  return (
    <div className="min-h-dvh bg-background text-foreground">
      <header className="border-b">
        <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
          <div className="flex items-center gap-6">
            <Link to="/" className="font-semibold">32-ways</Link>
            <nav className="hidden gap-4 sm:flex">
              <NavLink to="/dashboard" className={({ isActive }) => isActive ? "text-foreground" : "text-muted-foreground hover:text-foreground"}>Dashboard</NavLink>
              <NavLink to="/profile" className={({ isActive }) => isActive ? "text-foreground" : "text-muted-foreground hover:text-foreground"}>Profile</NavLink>
            </nav>
          </div>
          <div className="flex items-center gap-2">
            {user ? (
              <UserMenu />
            ) : (
              <Button asChild variant="outline" size="sm"><Link to="/login">Sign in</Link></Button>
            )}
          </div>
        </div>
      </header>
      <main className="mx-auto max-w-6xl px-4 py-6"><Outlet /></main>
    </div>
  )
}
EOF

# src/features/profile/pages/ProfilePage.tsx
cat > src/features/profile/pages/ProfilePage.tsx <<'EOF'
import * as React from "react"
import { useAuth } from "@/app/providers/auth-provider"
import { supabase } from "@/lib/supabase"
import { Button } from "@/components/ui/button"

export default function ProfilePage() {
  const { user } = useAuth()
  async function handleSignOut() { await supabase.auth.signOut(); window.location.href = "/login" }
  return (
    <section className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Profile</h1>
        <p className="text-sm text-muted-foreground">Your account details</p>
      </div>
      <div className="grid gap-4 rounded-lg border p-4 sm:grid-cols-2">
        <div><div className="text-xs text-muted-foreground">User ID</div><div className="font-mono text-sm">{user?.id}</div></div>
        <div><div className="text-xs text-muted-foreground">Email</div><div className="text-sm">{user?.email}</div></div>
        {user?.user_metadata?.full_name && (<div><div className="text-xs text-muted-foreground">Name</div><div className="text-sm">{String(user.user_metadata.full_name)}</div></div>)}
      </div>
      <div><Button variant="outline" onClick={handleSignOut}>Sign out</Button></div>
    </section>
  )
}
EOF

# src/features/auth/pages/ResetPasswordPage.tsx (with strength meter + hints)
cat > src/features/auth/pages/ResetPasswordPage.tsx <<'EOF'
import * as React from "react"
import { z } from "zod"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { supabase } from "@/lib/supabase"
import { Button } from "@/components/ui/button"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { Checkbox } from "@/components/ui/checkbox"
import { CheckCircle2, Circle } from "lucide-react"

const ResetPwdSchema = z.object({ password: z.string().min(8, "Password must be at least 8 characters"), confirm: z.string() }).refine((v) => v.password === v.confirm, { path: ["confirm"], message: "Passwords do not match" })

type ResetPwdValues = z.infer<typeof ResetPwdSchema>

function strengthOf(pw: string) {
  let score = 0
  const hasLower = /[a-z]/.test(pw)
  const hasUpper = /[A-Z]/.test(pw)
  const hasDigit = /[0-9]/.test(pw)
  const hasSymbol = /[^A-Za-z0-9]/.test(pw)
  const categories = [hasLower, hasUpper, hasDigit, hasSymbol].filter(Boolean).length
  score += Math.min(3, categories)
  if (pw.length >= 12) score += 2; else if (pw.length >= 8) score += 1
  score = Math.max(0, Math.min(4, score))
  const label = ["Very weak", "Weak", "Okay", "Strong", "Very strong"][score]
  return { score, label, hasLower, hasUpper, hasDigit, hasSymbol }
}

function friendlyErrorMessage(msg?: string) {
  const m = (msg || "").toLowerCase()
  if (m.includes("rate") && (m.includes("limit") || m.includes("too many") || m.includes("requests"))) return "Too many attempts right now. Please wait about a minute and try again."
  if (m.includes("expired") || m.includes("invalid")) return "This reset link is invalid or has expired. Request a new one from the login page."
  return msg || "Could not update password. Please try again."
}

export default function ResetPasswordPage() {
  const [ready, setReady] = React.useState(false)
  const [error, setError] = React.useState<string | null>(null)
  const [success, setSuccess] = React.useState(false)
  const [showMeter, setShowMeter] = React.useState(true)
  const [pw, setPw] = React.useState("")

  const form = useForm<ResetPwdValues>({ resolver: zodResolver(ResetPwdSchema), defaultValues: { password: "", confirm: "" }, mode: "onBlur" })

  React.useEffect(() => {
    let mounted = true
    ;(async () => {
      const { data, error } = await supabase.auth.getSession()
      if (!mounted) return
      if (error) setError(friendlyErrorMessage(error.message))
      setReady(true)
      if (!data.session) setError("This reset link is invalid or has expired. Request a new one from the login page.")
    })();
    return () => { mounted = false }
  }, [])

  async function onSubmit(values: ResetPwdValues) {
    setError(null)
    const { error } = await supabase.auth.updateUser({ password: values.password })
    if (error) { setError(friendlyErrorMessage(error.message)); return }
    setSuccess(true)
  }

  const s = strengthOf(pw)
  const hints = React.useMemo(() => ([
    { label: "Use 12+ characters", ok: pw.length >= 12 },
    { label: "Add a symbol", ok: s.hasSymbol },
    { label: "Include a number", ok: s.hasDigit },
    { label: "Add an uppercase letter", ok: s.hasUpper },
    { label: "Add a lowercase letter", ok: s.hasLower },
  ]), [pw.length, s.hasSymbol, s.hasDigit, s.hasUpper, s.hasLower])

  return (
    <div className="mx-auto flex min-h-dvh max-w-lg items-center px-4 py-12">
      <div className="w-full">
        <h1 className="text-2xl font-semibold">Set a new password</h1>
        <p className="mt-2 text-sm text-muted-foreground">Enter and confirm your new password to finish resetting your account.</p>
        {!ready ? (<div className="mt-6 text-sm text-muted-foreground">Loading…</div>) : success ? (
          <div className="mt-6 rounded-md border p-4 text-sm">Password updated successfully. You can now <a href="/login" className="underline">sign in</a>.</div>
        ) : (<>
          {error && (<p role="alert" className="mt-4 text-sm text-destructive">{error}</p>)}
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="mt-6 space-y-4">
              <FormField control={form.control} name="password" render={({ field }) => (
                <FormItem>
                  <FormLabel>New password</FormLabel>
                  <FormControl>
                    <Input type="password" placeholder="••••••••" {...field} onChange={(e) => { field.onChange(e); setPw(e.target.value) }} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )} />
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <Checkbox id="meter" checked={showMeter} onCheckedChange={(v) => setShowMeter(Boolean(v))} />
                  <label htmlFor="meter" className="text-sm text-muted-foreground">Show strength meter</label>
                </div>
                {showMeter && pw && (
                  <div className="space-y-2" aria-live="polite">
                    <div aria-hidden className="grid grid-cols-4 gap-1">
                      {[0,1,2,3].map((i) => (
                        <div key={i} className={"h-1.5 rounded-full bg-muted transition-colors " + (s.score > i ? (s.score <= 1 ? "bg-red-500" : s.score === 2 ? "bg-yellow-500" : "bg-emerald-500") : "")} />
                      ))}
                    </div>
                    <div className="text-xs text-muted-foreground">{s.label}</div>
                    <ul className="mt-1.5 space-y-1 text-xs">
                      {hints.map((h) => (
                        <li key={h.label} className="flex items-center gap-2">
                          {h.ok ? (<svg className="h-3.5 w-3.5 text-emerald-500" viewBox="0 0 24 24"><path d="M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z"/></svg>) : (<svg className="h-3.5 w-3.5 text-muted-foreground" viewBox="0 0 24 24"><circle cx="12" cy="12" r="5" /></svg>)}
                          <span className={h.ok ? "text-foreground" : "text-muted-foreground"}>{h.label}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
              <FormField control={form.control} name="confirm" render={({ field }) => (
                <FormItem>
                  <FormLabel>Confirm new password</FormLabel>
                  <FormControl><Input type="password" placeholder="••••••••" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />
              <Button type="submit" className="w-full" disabled={form.formState.isSubmitting}>Save new password</Button>
            </form>
          </Form>
        </>)}
      </div>
    </div>
  )
}
EOF

# src/lib/password-policy.ts (client-side helpers)
cat > src/lib/password-policy.ts <<'EOF'
import { z } from "zod"

export type PasswordPolicy = {
  minLength: number
  requireLower?: boolean
  requireUpper?: boolean
  requireDigit?: boolean
  requireSymbol?: boolean
  bannedSubstrings?: string[]
  maxRepeat?: number
}

export const DEFAULT_POLICY: PasswordPolicy = {
  minLength: 12,
  requireLower: true,
  requireUpper: true,
  requireDigit: true,
  requireSymbol: true,
  bannedSubstrings: [],
  maxRepeat: 3,
}

export function expandDynamicSubstrings(list: string[] | undefined, ctx?: { email?: string }) {
  const out: string[] = []
  for (const item of list ?? []) {
    if (item === "<emailLocalPart>") {
      const local = ctx?.email?.split("@")[0]
      if (local) out.push(local)
    } else {
      out.push(item)
    }
  }
  return out.filter(Boolean)
}

export function makePasswordSchema(policy: PasswordPolicy, ctx?: { email?: string }) {
  const banned = expandDynamicSubstrings(policy.bannedSubstrings, ctx)
  let schema = z.string({ required_error: "Password is required" }).min(policy.minLength, `Password must be at least ${policy.minLength} characters`)
  if (policy.requireLower) schema = schema.regex(/[a-z]/, "Add a lowercase letter")
  if (policy.requireUpper) schema = schema.regex(/[A-Z]/, "Add an uppercase letter")
  if (policy.requireDigit) schema = schema.regex(/[0-9]/, "Include a number")
  if (policy.requireSymbol) schema = schema.regex(/[^A-Za-z0-9]/, "Add a symbol")
  if (policy.maxRepeat && policy.maxRepeat > 0) {
    const n = policy.maxRepeat
    const repeat = new RegExp(`(.)\\1{${n},}`)
    schema = schema.refine((pw) => !repeat.test(pw), { message: `Avoid repeating the same character more than ${n} times in a row` })
  }
  if (banned.length) {
    schema = schema.refine((pw) => !banned.some((frag) => frag && pw.toLowerCase().includes(frag.toLowerCase())), { message: "Password contains a disallowed word" })
  }
  return schema
}

export function scorePassword(policy: PasswordPolicy, pw: string) {
  let score = 0
  const hasLower = /[a-z]/.test(pw)
  const hasUpper = /[A-Z]/.test(pw)
  const hasDigit = /[0-9]/.test(pw)
  const hasSymbol = /[^A-Za-z0-9]/.test(pw)
  const categories = [hasLower, hasUpper, hasDigit, hasSymbol].filter(Boolean).length
  score += Math.min(3, categories)
  if (pw.length >= Math.max(policy.minLength, 12)) score += 2; else if (pw.length >= policy.minLength) score += 1
  score = Math.max(0, Math.min(4, score))
  const label = ["Very weak", "Weak", "Okay", "Strong", "Very strong"][score]
  return { score, label, hasLower, hasUpper, hasDigit, hasSymbol }
}

export function buildHints(policy: PasswordPolicy, pw: string) {
  const s = scorePassword(policy, pw)
  const hints = [ { label: `Use ${policy.minLength}+ characters`, ok: pw.length >= policy.minLength } ] as { label: string; ok: boolean }[]
  if (policy.requireSymbol) hints.push({ label: "Add a symbol", ok: s.hasSymbol })
  if (policy.requireDigit) hints.push({ label: "Include a number", ok: s.hasDigit })
  if (policy.requireUpper) hints.push({ label: "Add an uppercase letter", ok: s.hasUpper })
  if (policy.requireLower) hints.push({ label: "Add a lowercase letter", ok: s.hasLower })
  if (policy.maxRepeat && policy.maxRepeat > 0) hints.push({ label: `Avoid ${policy.maxRepeat}+ repeats in a row", ok: !new RegExp(` + '"(.)\\1{' + '${policy.maxRepeat}' + ',}"' + ').test(pw) })
  return { s, hints }
}
EOF

# Router: backup then write updated router
if [ -f src/app/router.tsx ]; then
  cp src/app/router.tsx "src/app/router.tsx.bak.$(date +%s)"
  echo "• Backed up existing router.tsx"
fi

cat > src/app/router.tsx <<'EOF'
import { createBrowserRouter, Navigate } from "react-router-dom"
import AppLayout from "@/app/layout/AppLayout"
import LoginPage from "@/features/auth/pages/LoginPage"
import AuthCallback from "@/features/auth/pages/AuthCallback"
import ProtectedRoute from "@/app/routes/ProtectedRoute"
import { DashboardPage } from "@/features/dashboard/pages/DashboardPage"
import ProfilePage from "@/features/profile/pages/ProfilePage"
import ResetPasswordPage from "@/features/auth/pages/ResetPasswordPage"

export const router = createBrowserRouter([
  {
    path: "/",
    element: <AppLayout />,
    children: [
      { index: true, element: <Navigate to="/dashboard" replace /> },
      { path: "login", element: <LoginPage /> },
      { path: "auth/callback", element: <AuthCallback /> },
      { path: "auth/reset-password", element: <ResetPasswordPage /> },
      {
        element: <ProtectedRoute />,
        children: [
          { path: "dashboard", element: <DashboardPage /> },
          { path: "profile", element: <ProfilePage /> },
        ],
      },
    ],
  },
])
EOF

# Main: backup then write updated main
if [ -f src/app/main.tsx ]; then
  cp src/app/main.tsx "src/app/main.tsx.bak.$(date +%s)"
  echo "• Backed up existing main.tsx"
fi

cat > src/app/main.tsx <<'EOF'
import React from "react"
import ReactDOM from "react-dom/client"
import { RouterProvider } from "react-router-dom"
import "@/styles/globals.css"
import "@/styles/themes.css"
import { router } from "./router"
import { ThemeProvider } from "./providers/theme-provider"
import { AuthProvider } from "./providers/auth-provider"

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ThemeProvider>
      <AuthProvider>
        <RouterProvider router={router} />
      </AuthProvider>
    </ThemeProvider>
  </React.StrictMode>
)
EOF

# --- Install deps ---
echo "\n▶ Installing dependencies..."
pnpm add @supabase/supabase-js zod react-hook-form @hookform/resolvers lucide-react
pnpm dlx shadcn-ui@latest add form button input separator checkbox dialog label avatar dropdown-menu || true

# --- Env hints ---
if [ ! -f .env.example ] || ! grep -q "VITE_SUPABASE_URL" .env.example; then
  cat >> .env.example <<'ENVEOF'
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
ENVEOF
  echo "• Added Supabase keys to .env.example"
fi

# --- Optional Edge Functions ---
if [ "$CREATE_EDGE_FUNCTIONS" = "1" ]; then
  echo "\n▶ Creating Supabase Edge Functions (password policy + update)..."
  mkdir -p supabase/functions/{password-policy,validate-password,update-password}
  cat > supabase/functions/password-policy/index.ts <<'EOF'
import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
const POLICY = { minLength: 12, requireLower: true, requireUpper: true, requireDigit: true, requireSymbol: true, bannedSubstrings: ["<emailLocalPart>", "32-ways", "yourbrand"], maxRepeat: 3 }
serve((req) => req.method !== "GET" ? new Response("Method Not Allowed", { status: 405 }) : new Response(JSON.stringify(POLICY), { headers: { "content-type": "application/json", "cache-control": "public, max-age=60" } }))
EOF
  cat > supabase/functions/validate-password/index.ts <<'EOF'
import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
const POLICY = { minLength: 12, requireLower: true, requireUpper: true, requireDigit: true, requireSymbol: true, bannedSubstrings: ["<emailLocalPart>", "32-ways", "yourbrand"], maxRepeat: 3 }
function expand(list: string[] = [], email?: string) { return list.flatMap((s) => s === "<emailLocalPart>" ? (email?.split("@")[0] || []) : s).filter(Boolean) }
function validate(pw: string, email?: string) {
  const errors: string[] = []
  if (!pw || typeof pw !== "string") return ["Password required"]
  if (pw.length < POLICY.minLength) errors.push(`Password must be at least ${POLICY.minLength} characters`)
  if (POLICY.requireLower && !/[a-z]/.test(pw)) errors.push("Add a lowercase letter")
  if (POLICY.requireUpper && !/[A-Z]/.test(pw)) errors.push("Add an uppercase letter")
  if (POLICY.requireDigit && !/[0-9]/.test(pw)) errors.push("Include a number")
  if (POLICY.requireSymbol && !/[^A-Za-z0-9]/.test(pw)) errors.push("Add a symbol")
  if (POLICY.maxRepeat && /(.)\1{3,}/.test(pw)) errors.push("Avoid repeating the same character too many times")
  const banned = expand(POLICY.bannedSubstrings, email)
  if (banned.length && banned.some((b) => pw.toLowerCase().includes(String(b).toLowerCase()))) errors.push("Password contains a disallowed word")
  return errors
}
serve(async (req) => {
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 })
  const { password, email } = await req.json().catch(() => ({}))
  const errors = validate(password, email)
  return new Response(JSON.stringify({ valid: errors.length === 0, errors }), { headers: { "content-type": "application/json" }, status: 200 })
})
EOF
  cat > supabase/functions/update-password/index.ts <<'EOF'
import { serve } from "https://deno.land/std@0.224.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!
const ANON_KEY = Deno.env.get("ANON_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY")!
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
const POLICY = { minLength: 12, requireLower: true, requireUpper: true, requireDigit: true, requireSymbol: true, bannedSubstrings: ["<emailLocalPart>", "32-ways", "yourbrand"], maxRepeat: 3 }
function expand(list: string[] = [], email?: string) { return list.flatMap((s) => s === "<emailLocalPart>" ? (email?.split("@")[0] || []) : s).filter(Boolean) }
function validate(pw: string, email?: string) {
  const errors: string[] = []
  if (!pw || typeof pw !== "string") return ["Password required"]
  if (pw.length < POLICY.minLength) errors.push(`Password must be at least ${POLICY.minLength} characters`)
  if (POLICY.requireLower && !/[a-z]/.test(pw)) errors.push("Add a lowercase letter")
  if (POLICY.requireUpper && !/[A-Z]/.test(pw)) errors.push("Add an uppercase letter")
  if (POLICY.requireDigit && !/[0-9]/.test(pw)) errors.push("Include a number")
  if (POLICY.requireSymbol && !/[^A-Za-z0-9]/.test(pw)) errors.push("Add a symbol")
  if (POLICY.maxRepeat && /(.)\1{3,}/.test(pw)) errors.push("Avoid repeating the same character too many times")
  const banned = expand(POLICY.bannedSubstrings, email)
  if (banned.length && banned.some((b) => pw.toLowerCase().includes(String(b).toLowerCase()))) errors.push("Password contains a disallowed word")
  return errors
}
serve(async (req) => {
  if (req.method !== "POST") return new Response("Method Not Allowed", { status: 405 })
  const authHeader = req.headers.get("Authorization")
  if (!authHeader) return new Response("Unauthorized", { status: 401 })
  const userClient = createClient(SUPABASE_URL, ANON_KEY, { global: { headers: { Authorization: authHeader } } })
  const { data: userData, error: userErr } = await userClient.auth.getUser()
  if (userErr || !userData?.user) return new Response("Unauthorized", { status: 401 })
  const { password } = await req.json().catch(() => ({}))
  const email = userData.user.email ?? undefined
  const errors = validate(password, email)
  if (errors.length) return new Response(JSON.stringify({ ok: false, errors }), { status: 400, headers: { "content-type": "application/json" } })
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE)
  const { error: updErr } = await admin.auth.admin.updateUserById(userData.user.id, { password })
  if (updErr) return new Response(JSON.stringify({ ok: false, errors: [updErr.message] }), { status: 500, headers: { "content-type": "application/json" } })
  return new Response(JSON.stringify({ ok: true }), { status: 200, headers: { "content-type": "application/json" } })
})
EOF
  echo "• Edge function files created. Remember to: supabase secrets set SUPABASE_SERVICE_ROLE_KEY=... && supabase functions deploy ..."
fi

cat <<'DONE'

✅ Auth scaffold applied.

Next steps:
  1) Put your keys in .env.local or .env:
       VITE_SUPABASE_URL=...
       VITE_SUPABASE_ANON_KEY=...
  2) In Supabase Dashboard → Authentication → URL Configuration, allow:
       http://localhost:5173/auth/callback
       http://localhost:5173/auth/reset-password
  3) Run the app: pnpm dev
  4) (Optional) Commit & open PR:
       git checkout -b feat/auth-supabase-login
       git add -A && git commit -m "feat: Supabase auth + login flow"
       git push -u origin feat/auth-supabase-login
       gh pr create -B main -t "feat: Supabase auth + polished login flow" -b "Adds Supabase auth, login, reset, profile, router wiring"

DONE
