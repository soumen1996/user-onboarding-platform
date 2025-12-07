import React, { createContext, useContext, useState, useEffect } from "react";
import api from "../services/api";

type User = { id: number; email: string; full_name?: string; role: string; status?: string };

type AuthContextType = {
  user: User | null;
  token: string | null;
  signin: (token: string, user: User) => void;
  signout: () => void;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{children: React.ReactNode}> = ({ children }) => {
  const [token, setToken] = useState<string | null>(() => localStorage.getItem("access_token"));
  const [user, setUser] = useState<User | null>(() => {
    const raw = localStorage.getItem("current_user");
    return raw ? JSON.parse(raw) : null;
  });

  useEffect(() => {
    if (token) {
      api.setAuthToken(token);
      localStorage.setItem("access_token", token);
    } else {
      api.clearAuthToken();
      localStorage.removeItem("access_token");
    }
  }, [token]);

  useEffect(() => {
    if (user) localStorage.setItem("current_user", JSON.stringify(user));
    else localStorage.removeItem("current_user");
  }, [user]);

  const signin = (newToken: string, u: User) => {
    setToken(newToken);
    setUser(u);
  };

  const signout = () => {
    setToken(null);
    setUser(null);
    localStorage.removeItem("access_token");
    localStorage.removeItem("current_user");
  };

  return <AuthContext.Provider value={{ user, token, signin, signout }}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
};
