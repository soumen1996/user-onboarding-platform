import React, { useState } from "react";
import api from "../services/api";
import { useNavigate } from "react-router-dom";

export default function Register() {
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const navigate = useNavigate();

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null); setSuccess(null);
    if (!fullName || !email || !password || !confirm) { setError("All fields are required"); return; }
    if (password.length < 8) { setError("Password must be at least 8 characters"); return; }
    if (password !== confirm) { setError("Passwords do not match"); return; }
    try {
      const res = await api.post("/auth/register", { email, password, full_name: fullName });
      setSuccess("Registered successfully. Awaiting approval.");
      // optional redirect to login
      setTimeout(() => navigate("/login"), 1500);
    } catch (err: any) {
      setError(err?.response?.data?.detail || "Registration failed");
    }
  };

  return (
    <div className="container">
      <h2>Register</h2>
      <form onSubmit={submit} className="form">
        <label>Full name<input value={fullName} onChange={e=>setFullName(e.target.value)} /></label>
        <label>Email<input value={email} onChange={e=>setEmail(e.target.value)} /></label>
        <label>Password<input type="password" value={password} onChange={e=>setPassword(e.target.value)} /></label>
        <label>Confirm password<input type="password" value={confirm} onChange={e=>setConfirm(e.target.value)} /></label>
        <button type="submit">Register</button>
      </form>
      {error && <div className="error">{error}</div>}
      {success && <div className="success">{success}</div>}
    </div>
  );
}
