import React, { useState } from "react";
import api from "../services/api";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();
  const { signin } = useAuth();

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    try {
      const res = await api.post("/auth/login", { email, password });
      const token = res.data.access_token;
      // Decode role from token client-side minimally (unsafe) or call /me to fetch user
      // We'll call /me to get user info
      api.setAuthToken(token);
      const me = await api.get("/me");
      signin(token, me.data);
      if (me.data.role === "ADMIN") navigate("/admin");
      else navigate("/me");
    } catch (err: any) {
      setError(err?.response?.data?.detail || "Login failed");
    }
  };

  return (
    <div className="container">
      <h2>Login</h2>
      <form onSubmit={submit} className="form">
        <label>Email<input value={email} onChange={e=>setEmail(e.target.value)} /></label>
        <label>Password<input type="password" value={password} onChange={e=>setPassword(e.target.value)} /></label>
        <button type="submit">Login</button>
      </form>
      {error && <div className="error">{error}</div>}
    </div>
  );
}
