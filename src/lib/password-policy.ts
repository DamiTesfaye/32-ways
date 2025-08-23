import {z} from "zod"

export type PasswordPolicy = {
    minLength: number
    requireLower?: boolean
    requireUpper?: boolean
    requireDigit?: boolean
    requireSymbol?: boolean
    bannedSubstrings?: string[]
    maxRepeat?: number
}

export const DEFAULT_POLICY: PasswordPolicy = {
    minLength: 12,
    requireLower: true,
    requireUpper: true,
    requireDigit: true,
    requireSymbol: true,
    bannedSubstrings: [],
    maxRepeat: 3,
}

export function expandDynamicSubstrings(list: string[] | undefined, ctx?: { email?: string }) {
    const out: string[] = []
    for (const item of list ?? []) {
        if (item === "<emailLocalPart>") {
            const local = ctx?.email?.split("@")[0]
            if (local) out.push(local)
        } else {
            out.push(item)
        }
    }
    return out.filter(Boolean)
}

export function makePasswordSchema(policy: PasswordPolicy, ctx?: { email?: string }) {
    const banned = expandDynamicSubstrings(policy.bannedSubstrings, ctx)
    let schema = z.string().min(policy.minLength, `Password must be at least ${policy.minLength} characters`)
    if (policy.requireLower) schema = schema.regex(/[a-z]/, "Add a lowercase letter")
    if (policy.requireUpper) schema = schema.regex(/[A-Z]/, "Add an uppercase letter")
    if (policy.requireDigit) schema = schema.regex(/[0-9]/, "Include a number")
    if (policy.requireSymbol) schema = schema.regex(/[^A-Za-z0-9]/, "Add a symbol")
    if (policy.maxRepeat && policy.maxRepeat > 0) {
        const n = policy.maxRepeat
        const repeat = new RegExp(`(.)\\1{${n},}`)
        schema = schema.refine((pw) => !repeat.test(pw), {message: `Avoid repeating the same character more than ${n} times in a row`})
    }
    if (banned.length) {
        schema = schema.refine((pw) => !banned.some((frag) => frag && pw.toLowerCase().includes(frag.toLowerCase())), {message: "Password contains a disallowed word"})
    }
    return schema
}


export function buildHints(policy: PasswordPolicy, pw: string) {
    const s = scorePassword(policy, pw)
    const hints = [{label: `Use ${policy.minLength}+ characters`, ok: pw.length >= policy.minLength}] as {
        label: string;
        ok: boolean
    }[]
    if (policy.requireSymbol) hints.push({label: "Add a symbol", ok: s.hasSymbol})
    if (policy.requireDigit) hints.push({label: "Include a number", ok: s.hasDigit})
    if (policy.requireUpper) hints.push({label: "Add an uppercase letter", ok: s.hasUpper})
    if (policy.requireLower) hints.push({label: "Add a lowercase letter", ok: s.hasLower})

    if (policy.maxRepeat && policy.maxRepeat > 0) {
        const re = new RegExp(String.raw`(.)\1{${policy.maxRepeat},}`)
        hints.push({
            label: `Avoid ${policy.maxRepeat}+ repeats in a row`,
            ok: !re.test(pw),
        })
    }

    return {s, hints}
}

export function scorePassword(policy: PasswordPolicy, pw: string) {
    let score = 0
    const hasLower = /[a-z]/.test(pw)
    const hasUpper = /[A-Z]/.test(pw)
    const hasDigit = /[0-9]/.test(pw)
    const hasSymbol = /[^A-Za-z0-9]/.test(pw)
    const categories = [hasLower, hasUpper, hasDigit, hasSymbol].filter(Boolean).length
    score += Math.min(3, categories)
    if (pw.length >= Math.max(policy.minLength, 12)) score += 2; else if (pw.length >= policy.minLength) score += 1
    score = Math.max(0, Math.min(4, score))
    const label = ["Very weak", "Weak", "Okay", "Strong", "Very strong"][score]
    return {score, label, hasLower, hasUpper, hasDigit, hasSymbol}
}