import {Outlet} from "react-router-dom"

export function RootLayout() {
    return (
        <div className="flex min-h-screen items-center justify-center bg-gray-50 p-4">
            {/* You could add a shared Header or Footer here */}
            <Outlet/>
        </div>
    )
}