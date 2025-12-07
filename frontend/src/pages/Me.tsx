import React, { useEffect, useState } from "react";
import api from "../services/api";
import { useAuth } from "../contexts/AuthContext";

export default function Me() {
  const { user } = useAuth();
  const [data, setData] = useState<any>(null);
  const [status, setStatus] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;
    const fetch = async () => {
      try {
        const me = await api.get("/me");
        const st = await api.get("/me/status");
        if (!mounted) return;
        setData(me.data);
        setStatus(st.data);
      } catch (err) {
        // ignore
      } finally { if (mounted) setLoading(false); }
    };
    fetch();
    return () => { mounted = false; };
  }, []);

  if (loading) return <div className="container">Loading...</div>;
  return (
    <div className="container">
      <h2>My Account</h2>
      <div><strong>Name:</strong> {data?.full_name}</div>
      <div><strong>Email:</strong> {data?.email}</div>
      <div>
        <strong>Status:</strong>
        <span className={`status ${status?.status?.toLowerCase()}`}> {status?.status}</span>
      </div>
      {status?.status === "REJECTED" && <div className="error">Reason: {status?.rejection_reason}</div>}
    </div>
  );
}
