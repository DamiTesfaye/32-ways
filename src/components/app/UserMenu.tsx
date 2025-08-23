import {useNavigate} from "react-router-dom"
import {LogOut, User as UserIcon} from "lucide-react"
import {Avatar, AvatarFallback, AvatarImage} from "@/components/ui/avatar"
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger
} from "@/components/ui/dropdown-menu"
import {Button} from "@/components/ui/button"
import {useAuth} from "@/app/providers/auth-provider"
import {supabase} from "@/lib/supabase"

function initialFromEmail(email?: string | null) {
    return email ? email.charAt(0).toUpperCase() : "?"
}

export function UserMenu() {
    const {user} = useAuth()
    const navigate = useNavigate()

    const email = user?.email ?? user?.user_metadata?.email
    const name = user?.user_metadata.full_name as string | undefined
    const avatarUrl = user?.user_metadata.avatar_url as string | undefined

    async function signOut() {
        await supabase.auth.signOut();
        navigate("/login", {replace: true})
    }

    return (
        <DropdownMenu>
            <DropdownMenuTrigger asChild>
                <Button variant="ghost" className="h-9 w-9 rounded-full p-0" aria-label="User menu">
                    <Avatar className="h-9 w-9">
                        <AvatarImage src={avatarUrl} alt={name ?? email ?? "User"}/>
                        <AvatarFallback>{initialFromEmail(email)}</AvatarFallback>
                    </Avatar>
                </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-56">
                <DropdownMenuLabel className="truncate">
                    <div className="text-sm font-medium leading-tight truncate">{name ?? email ?? "Account"}</div>
                    {email && name && (<div className="text-xs text-muted-foreground truncate">{email}</div>)}
                </DropdownMenuLabel>
                <DropdownMenuSeparator/>
                <DropdownMenuItem onSelect={() => navigate("/profile")}><UserIcon
                    className="mr-2 h-4 w-4"/> Profile</DropdownMenuItem>
                <DropdownMenuSeparator/>
                <DropdownMenuItem className="text-destructive focus:text-destructive" onSelect={signOut}><LogOut
                    className="mr-2 h-4 w-4"/> Sign out</DropdownMenuItem>
            </DropdownMenuContent>
        </DropdownMenu>
    )
}
