import React from "react"
import ReactDOM from "react-dom/client"
import {RouterProvider} from "react-router-dom"
import "@/styles/globals.css"
import "@/styles/themes.css"
import {router} from "./router"
import {ThemeProvider} from "./providers/theme-provider"
import {AuthProvider} from "./providers/auth-provider"

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <ThemeProvider>
        <AuthProvider>
            <RouterProvider router={router}/>
        </AuthProvider>
    </ThemeProvider>
  </React.StrictMode>
)
