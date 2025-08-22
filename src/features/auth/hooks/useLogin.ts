import * as React from "react"
import { login } from "../api"
export function useLogin(){
  const [loading, setLoading] = React.useState(false)
  const [error, setError] = React.useState<string | null>(null)
  const run = async (email:string, password:string) => {
    setLoading(true); setError(null)
    try { return await login(email, password) }
    catch (e:any){ setError(e?.message ?? "Login failed") }
    finally { setLoading(false) }
  }
  return { run, loading, error }
}
