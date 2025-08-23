import {useAuth} from "@/app/providers/auth-provider"
import {supabase} from "@/lib/supabase"
import {Button} from "@/components/ui/button"

export default function ProfilePage() {
    const {user} = useAuth()

    async function handleSignOut() {
        await supabase.auth.signOut();
        window.location.href = "/login"
    }

    return (
        <section className="space-y-6">
            <div>
                <h1 className="text-2xl font-semibold">Profile</h1>
                <p className="text-sm text-muted-foreground">Your account details</p>
            </div>
            <div className="grid gap-4 rounded-lg border p-4 sm:grid-cols-2">
                <div>
                    <div className="text-xs text-muted-foreground">User ID</div>
                    <div className="font-mono text-sm">{user?.id}</div>
                </div>
                <div>
                    <div className="text-xs text-muted-foreground">Email</div>
                    <div className="text-sm">{user?.email}</div>
                </div>
                {user?.user_metadata?.full_name && (<div>
                    <div className="text-xs text-muted-foreground">Name</div>
                    <div className="text-sm">{String(user.user_metadata.full_name)}</div>
                </div>)}
            </div>
            <div><Button variant="outline" onClick={handleSignOut}>Sign out</Button></div>
        </section>
    )
}
