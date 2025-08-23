import * as React from "react"
import {login} from "../api"

export function use_login() {
  const [loading, setLoading] = React.useState(false)
  const [error, setError] = React.useState<string | null>(null)
  const run = async (email:string, password:string) => {
    setLoading(true); setError(null)
    try {
      return await login(email, password)
    } catch (e) {
      setError(e instanceof Error ? e?.message : "Login failed")
    }
    finally { setLoading(false) }
  }
  return { run, loading, error }
}
