import {createBrowserRouter, Navigate} from "react-router-dom"
import AppLayout from "@/app/layout/AppLayout"
import LoginPage from "@/features/auth/pages/LoginPage"
import AuthCallback from "@/features/auth/pages/AuthCallback"
import ProtectedRoute from "@/app/routes/ProtectedRoute"
import {DashboardPage} from "@/features/dashboard/pages/DashboardPage"
import ProfilePage from "@/features/profile/pages/ProfilePage"
import ResetPasswordPage from "@/features/auth/pages/ResetPasswordPage"

export const router = createBrowserRouter([
  {
    path: "/",
    element: <AppLayout />,
    children: [
        {index: true, element: <Navigate to="/dashboard" replace/>},
        {path: "login", element: <LoginPage/>},
        {path: "auth/callback", element: <AuthCallback/>},
        {path: "auth/reset-password", element: <ResetPasswordPage/>},
        {
            element: <ProtectedRoute/>,
            children: [
                {path: "dashboard", element: <DashboardPage/>},
                {path: "profile", element: <ProfilePage/>},
            ],
        },
    ],
  },
])
