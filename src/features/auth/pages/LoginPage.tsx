import * as React from "react"
import {Apple, Eye, EyeOff, Loader2, Lock, Mail} from "lucide-react"
import {type SubmitHandler, useForm} from "react-hook-form"
import {z} from "zod"
import {zodResolver} from "@hookform/resolvers/zod"
import {useLocation, useNavigate} from "react-router-dom"
import {supabase} from "@/lib/supabase"
import {friendlyErrorMessage} from "@/features/auth/lib/utils"

// shadcn/ui
import {Button} from "@/components/ui/button"
import {Input} from "@/components/ui/input"
import {Separator} from "@/components/ui/separator"
import {Form, FormControl, FormField, FormItem, FormLabel, FormMessage,} from "@/components/ui/form"
import {Checkbox} from "@/components/ui/checkbox"
import {ResetPasswordDialog} from "@/features/auth/components/ResetPasswordDialog"
import {authStorage, purgeSupabaseTokens} from "@/lib/auth_storage.ts";

const LoginSchema = z.object({
  email: z.email("Enter a valid email"),
  password: z.string().min(6, "Password must be at least 6 characters"),
  remember: z.boolean(),
})
type LoginValues = z.infer<typeof LoginSchema>

export default function LoginPage() {
  const nav = useNavigate()
  const location = useLocation()
  const from = (location.state as { from?: string } | null)?.from || "/dashboard"

  const [showPassword, setShowPassword] = React.useState(false)
  const [oauthError, setOauthError] = React.useState<string | null>(null)

  const form = useForm<LoginValues>({
    resolver: zodResolver(LoginSchema),
    defaultValues: {email: "", password: ""},
    mode: "onBlur"
  })

  const onSubmit: SubmitHandler<LoginValues> = async (values) => {
    setOauthError(null)
    form.clearErrors("root")

    const {error} = await supabase.auth.signInWithPassword({email: values.email, password: values.password})

    if (error) {
      const msg = friendlyErrorMessage(error.message)
      if (/email/i.test(msg)) form.setError("email", {message: msg})
      else if (/password/i.test(msg)) form.setError("password", {message: msg})
      else form.setError("root", {message: msg})
      return
    }

    if (values.remember) {
      authStorage.setMode("local")
    } else {
      authStorage.setMode("memory")
      purgeSupabaseTokens()
    }

    nav(from, {replace: true})
  }

  async function handleOAuth(provider: "google" | "apple") {
    setOauthError(null)
    try {
      const redirect = `${window.location.origin}/auth/callback?next=${encodeURIComponent(from)}`
      const {error} = await supabase.auth.signInWithOAuth({provider, options: {redirectTo: redirect}})
      if (error) {
        setOauthError(friendlyErrorMessage(error.message))
        return
      }
    } catch (e) {
      setOauthError(friendlyErrorMessage(e instanceof Error ? e.message : undefined))
    }
  }

  return (
      <div className="min-h-dvh w-full bg-muted/30 py-8 md:py-12 lg:py-16 transition-colors">
        <div className="mx-auto max-w-6xl px-3 sm:px-6">
          <div
              className="grid gap-6 rounded-2xl border bg-background shadow-sm ring-1 ring-border/40 lg:grid-cols-2 lg:gap-0"
              style={{background: "linear-gradient(135deg, #EDE8E5 0%, #D1CCC9 100%)"}}>
            <aside
                className="relative hidden overflow-hidden rounded-t-2xl lg:block lg:rounded-l-2xl lg:rounded-tr-none">
              <div className="absolute inset-0 bg-gradient-to-b from-transparent to-black/10 dark:to-white/10"/>
              <img src="src/assets/images/ways_post_signs.jpg" alt="Playful machine illustration"
                   className="h-full w-full object-cover" loading="lazy"/>
            </aside>

            <section className="flex items-center justify-center px-4 py-8 sm:px-8 sm:py-10 lg:p-12">
              <div className="w-full max-w-md">
                <div className="mb-8 hidden items-center justify-end text-xs text-muted-foreground lg:flex">
                  <span className="mr-1">Don't have an account?</span>
                  <a href="#" className="font-medium text-foreground underline-offset-4 hover:underline">Sign up</a>
                </div>

                <h1 className="text-2xl font-semibold tracking-tight sm:text-3xl">Sign in</h1>
                <p className="mt-2 text-sm text-muted-foreground">Sign in with your account</p>

                <div className="mt-4 flex flex-col gap-3 sm:flex-row ">
                  <Button variant="outline"
                          className="flex-1 justify-center gap-2 shadow-sm hover:shadow transition-shadow" type="button"
                          onClick={() => handleOAuth("google")} aria-label="Continue with Google">
                    <svg viewBox="0 0 24 24" aria-hidden="true" className="h-4 w-4">
                      <path fill="#EA4335"
                            d="M12 10.2v3.9h5.4c-.2 1.3-1.6 3.7-5.4 3.7-3.3 0-6-2.7-6-6s2.7-6 6-6c1.9 0 3.2.8 3.9 1.5l2.6-2.5C16.9 3 14.7 2 12 2 6.9 2 2.8 6.1 2.8 11.2S6.9 20.4 12 20.4c6.9 0 9.5-4.8 8.9-9.1H12z"/>
                    </svg>
                    Google
                  </Button>
                  <Button variant="outline"
                          className="flex-1 justify-center gap-2 shadow-sm hover:shadow transition-shadow" type="button"
                          onClick={() => handleOAuth("apple")} aria-label="Continue with Apple">
                    <Apple className="h-4 w-4"/>
                    Apple ID
                  </Button>
                </div>
                {oauthError && (<p role="alert" className="mt-2 text-xs text-destructive">{oauthError}</p>)}

                <div className="my-6">
                  <div className="flex items-center gap-3 text-xs text-muted-foreground">
                    <Separator className="flex-1"/>
                    <span>Or continue with email address</span>
                    <Separator className="flex-1"/>
                  </div>
                </div>

                <Form {...form}>
                  <form onSubmit={form.handleSubmit(onSubmit)} noValidate className="space-y-4">
                    <FormField control={form.control} name="email" render={({field}) => (
                        <FormItem>
                          <FormLabel>Email address</FormLabel>
                          <FormControl>
                            <div className="relative">
                              <Mail
                                  className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground"/>
                              <Input type="email" placeholder="tami@uilt.net" className="pl-9" {...field} />
                            </div>
                          </FormControl>
                          <FormMessage/>
                        </FormItem>
                    )}/>

                    <FormField control={form.control} name="password" render={({field}) => (
                        <FormItem>
                          <div className="flex items-center justify-between">
                            <FormLabel>Password</FormLabel>
                            <ResetPasswordDialog/>
                          </div>
                          <FormControl>
                            <div className="relative">
                              <Lock
                                  className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground"/>
                              <Input type={showPassword ? "text" : "password"} placeholder="••••••••"
                                     className="pl-9 pr-10" {...field} />
                              <button type="button" aria-label={showPassword ? "Hide password" : "Show password"}
                                      className="absolute right-2 top-1/2 -translate-y-1/2 rounded-md p-2 text-muted-foreground hover:bg-accent hover:text-accent-foreground"
                                      onClick={() => setShowPassword((s) => !s)}>
                                {showPassword ? <EyeOff className="h-4 w-4"/> : <Eye className="h-4 w-4"/>}
                              </button>
                            </div>
                          </FormControl>
                          <FormMessage/>
                        </FormItem>
                    )}/>

                    <FormField control={form.control} name="remember" render={({field}) => (
                        <FormItem className="flex flex-row items-center space-x-2">
                          <FormControl>
                            <Checkbox checked={field.value} onCheckedChange={field.onChange} id="remember-me"/>
                          </FormControl>
                          <FormLabel htmlFor="remember-me" className="!mt-0 cursor-pointer font-normal">
                            Remember me
                          </FormLabel>
                        </FormItem>
                    )}/>

                    {form.formState.errors.root?.message && (
                        <p role="alert" className="text-xs text-destructive">{form.formState.errors.root?.message}</p>
                    )}

                    <Button type="submit" className="w-full" disabled={form.formState.isSubmitting}>
                      {form.formState.isSubmitting ? (<><Loader2 className="mr-2 h-4 w-4 animate-spin"/> Signing
                        in…</>) : (<>Start trading</>)}
                    </Button>
                  </form>
                </Form>

                <p className="mt-6 text-center text-xs text-muted-foreground lg:hidden">
                  Don't have an account? <a href="#"
                                            className="font-medium text-foreground underline-offset-4 hover:underline">Sign
                  up</a>
                </p>
              </div>
            </section>
          </div>
        </div>
    </div>
  )
}
