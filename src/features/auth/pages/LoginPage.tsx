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
