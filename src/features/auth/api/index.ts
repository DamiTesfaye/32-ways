export async function login(email: string, password: string) {
  // TODO: wire to real API
  await new Promise((r)=>setTimeout(r, 400))
  return { token: password, user: { email } }
}
