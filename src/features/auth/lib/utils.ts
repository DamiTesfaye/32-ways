export function friendlyErrorMessage(msg?: string) {
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