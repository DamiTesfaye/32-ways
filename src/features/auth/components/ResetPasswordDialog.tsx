import * as React from "react"
import {z} from "zod"
import {useForm} from "react-hook-form"
import {zodResolver} from "@hookform/resolvers/zod"
import {supabase} from "@/lib/supabase"
import {friendlyErrorMessage} from "@/features/auth/lib/utils"

import {Button} from "@/components/ui/button"
import {Input} from "@/components/ui/input"
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from "@/components/ui/dialog"
import {Form, FormControl, FormField, FormItem, FormLabel, FormMessage} from "@/components/ui/form"

const ResetSchema = z.object({
    email: z.string().min(1, "Email is required").email("Enter a valid email"),
})

type ResetValues = z.infer<typeof ResetSchema>

export function ResetPasswordDialog() {
    const [resetOpen, setResetOpen] = React.useState(false)
    const [resetInfo, setResetInfo] = React.useState<string | null>(null)

    const resetForm = useForm<ResetValues>({
        resolver: zodResolver(ResetSchema),
        defaultValues: {email: ""},
        mode: "onBlur",
    })

    async function onSendReset(values: ResetValues) {
        setResetInfo(null)
        try {
            const redirectTo = `${window.location.origin}/auth/reset-password`
            const {error} = await supabase.auth.resetPasswordForEmail(values.email, {redirectTo})
            if (error) throw error
            setResetInfo("If an account exists for that email, a reset link has been sent.")
        } catch (e) {
            resetForm.setError("email", {message: friendlyErrorMessage(e instanceof Error ? e.message : undefined)})
        }
    }

    return (
        <Dialog open={resetOpen} onOpenChange={setResetOpen}>
            <DialogTrigger asChild>
                <button className="text-xs text-muted-foreground underline-offset-4 hover:underline"
                        type="button">Forgot password?
                </button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-md">
                <DialogHeader>
                    <DialogTitle>Reset password</DialogTitle>
                    <DialogDescription>Enter your email and we'll send you a reset link.</DialogDescription>
                </DialogHeader>
                <Form {...resetForm}>
                    <form onSubmit={resetForm.handleSubmit(onSendReset)} className="space-y-3">
                        <FormField control={resetForm.control} name="email" render={({field}) => (
                            <FormItem>
                                <FormLabel>Email</FormLabel>
                                <FormControl><Input type="email"
                                                    placeholder="you@example.com" {...field} /></FormControl>
                                <FormMessage/>
                            </FormItem>
                        )}/>
                        {resetInfo && <p className="text-xs text-muted-foreground">{resetInfo}</p>}
                        <DialogFooter>
                            <Button type="submit" className="w-full sm:w-auto"
                                    disabled={resetForm.formState.isSubmitting}>Send reset link</Button>
                        </DialogFooter>
                    </form>
                </Form>
            </DialogContent>
        </Dialog>
    )
}