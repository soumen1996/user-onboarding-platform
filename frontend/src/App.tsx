import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import Register from "./pages/Register";
import Login from "./pages/Login";
import Me from "./pages/Me";
import Admin from "./pages/Admin";
import { useAuth } from "./contexts/AuthContext";

function PrivateRoute({ children, role }: { children: React.ReactElement, role?: "USER" | "ADMIN" }) {
  const { user } = useAuth();
  if (!user) return <Navigate to="/login" replace />;
  if (role && user.role !== role) return <Navigate to="/login" replace />;
  return children;
}

export default function App(){
  return (
    <Routes>
      <Route path="/register" element={<Register />} />
      <Route path="/login" element={<Login />} />
      <Route path="/me" element={<PrivateRoute role="USER"><Me /></PrivateRoute>} />
      <Route path="/admin" element={<PrivateRoute role="ADMIN"><Admin /></PrivateRoute>} />
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}
