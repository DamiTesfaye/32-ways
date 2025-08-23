import {StrictMode} from 'react'
import {createRoot} from 'react-dom/client'
import {createBrowserRouter, RouterProvider} from "react-router-dom"
import './index.css'
import {RootLayout} from "@/components/Layout";
import {DashboardPage} from '@/features/dashboard'
import LoginPage from "@/features/auth/pages/LoginPage.tsx";

const router = createBrowserRouter([
  {
    path: "/",
    element: <RootLayout/>,
    children: [
      {
        index: true,
        element: <LoginPage/>,
      },
      {
        path: "dashboard",
        element: <DashboardPage/>,
      },
    ],
  },
])

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <RouterProvider router={router}/>
  </StrictMode>,
)
