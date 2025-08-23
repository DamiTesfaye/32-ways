import * as React from "react"
import {z} from "zod"
import {useForm} from "react-hook-form"
import {zodResolver} from "@hookform/resolvers/zod"
import {supabase} from "@/lib/supabase"
import {Button} from "@/components/ui/button"
import {Form, FormControl, FormField, FormItem, FormLabel, FormMessage} from "@/components/ui/form"
import {Input} from "@/components/ui/input"
import {Checkbox} from "@/components/ui/checkbox"
import {DEFAULT_POLICY, scorePassword} from "@/lib/password-policy.ts";

const ResetPwdSchema = z.object({
    password: z.string().min(8, "Password must be at least 8 characters"),
    confirm: z.string()
}).refine((v) => v.password === v.confirm, {path: ["confirm"], message: "Passwords do not match"})

type ResetPwdValues = z.infer<typeof ResetPwdSchema>

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

    const form = useForm<ResetPwdValues>({
        resolver: zodResolver(ResetPwdSchema),
        defaultValues: {password: "", confirm: ""},
        mode: "onBlur"
    })

    React.useEffect(() => {
        let mounted = true
        ;(async () => {
            const {data, error} = await supabase.auth.getSession()
            if (!mounted) return
            if (error) setError(friendlyErrorMessage(error.message))
            setReady(true)
            if (!data.session) setError("This reset link is invalid or has expired. Request a new one from the login page.")
        })();
        return () => {
            mounted = false
        }
    }, [])

    async function onSubmit(values: ResetPwdValues) {
        setError(null)
        const {error} = await supabase.auth.updateUser({password: values.password})
        if (error) {
            setError(friendlyErrorMessage(error.message));
            return
        }
        setSuccess(true)
    }

    const s = scorePassword(DEFAULT_POLICY, pw)

    const hints = React.useMemo(() => ([
        {label: "Use 12+ characters", ok: pw.length >= DEFAULT_POLICY.minLength},
        {label: "Add a symbol", ok: s.hasSymbol},
        {label: "Include a number", ok: s.hasDigit},
        {label: "Add an uppercase letter", ok: s.hasUpper},
        {label: "Add a lowercase letter", ok: s.hasLower},
    ]), [pw.length, s.hasSymbol, s.hasDigit, s.hasUpper, s.hasLower])

    return (
        <div className="mx-auto flex min-h-dvh max-w-lg items-center px-4 py-12">
            <div className="w-full">
                <h1 className="text-2xl font-semibold">Set a new password</h1>
                <p className="mt-2 text-sm text-muted-foreground">Enter and confirm your new password to finish
                    resetting your account.</p>
                {!ready ? (<div className="mt-6 text-sm text-muted-foreground">Loading…</div>) : success ? (
                    <div className="mt-6 rounded-md border p-4 text-sm">Password updated successfully. You can now <a
                        href="/login" className="underline">sign in</a>.</div>
                ) : (<>
                    {error && (<p role="alert" className="mt-4 text-sm text-destructive">{error}</p>)}
                    <Form {...form}>
                        <form onSubmit={form.handleSubmit(onSubmit)} className="mt-6 space-y-4">
                            <FormField control={form.control} name="password" render={({field}) => (
                                <FormItem>
                                    <FormLabel>New password</FormLabel>
                                    <FormControl>
                                        <Input type="password" placeholder="••••••••" {...field} onChange={(e) => {
                                            field.onChange(e);
                                            setPw(e.target.value)
                                        }}/>
                                    </FormControl>
                                    <FormMessage/>
                                </FormItem>
                            )}/>
                            <div className="space-y-2">
                                <div className="flex items-center gap-2">
                                    <Checkbox id="meter" checked={showMeter}
                                              onCheckedChange={(v) => setShowMeter(Boolean(v))}/>
                                    <label htmlFor="meter" className="text-sm text-muted-foreground">Show strength
                                        meter</label>
                                </div>
                                {showMeter && pw && (
                                    <div className="space-y-2" aria-live="polite">
                                        <div aria-hidden className="grid grid-cols-4 gap-1">
                                            {[0, 1, 2, 3].map((i) => (
                                                <div key={i}
                                                     className={"h-1.5 rounded-full bg-muted transition-colors " + (s.score > i ? (s.score <= 1 ? "bg-red-500" : s.score === 2 ? "bg-yellow-500" : "bg-emerald-500") : "")}/>
                                            ))}
                                        </div>
                                        <div className="text-xs text-muted-foreground">{s.label}</div>
                                        <ul className="mt-1.5 space-y-1 text-xs">
                                            {hints.map((h) => (
                                                <li key={h.label} className="flex items-center gap-2">
                                                    {h.ok ? (<svg className="h-3.5 w-3.5 text-emerald-500"
                                                                  viewBox="0 0 24 24">
                                                        <path d="M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z"/>
                                                    </svg>) : (<svg className="h-3.5 w-3.5 text-muted-foreground"
                                                                    viewBox="0 0 24 24">
                                                        <circle cx="12" cy="12" r="5"/>
                                                    </svg>)}
                                                    <span
                                                        className={h.ok ? "text-foreground" : "text-muted-foreground"}>{h.label}</span>
                                                </li>
                                            ))}
                                        </ul>
                                    </div>
                                )}
                            </div>
                            <FormField control={form.control} name="confirm" render={({field}) => (
                                <FormItem>
                                    <FormLabel>Confirm new password</FormLabel>
                                    <FormControl><Input type="password"
                                                        placeholder="••••••••" {...field} /></FormControl>
                                    <FormMessage/>
                                </FormItem>
                            )}/>
                            <Button type="submit" className="w-full" disabled={form.formState.isSubmitting}>Save new
                                password</Button>
                        </form>
                    </Form>
                </>)}
            </div>
        </div>
    )
}
