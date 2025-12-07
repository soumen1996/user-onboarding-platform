import React, { useEffect, useState } from "react";
import api from "../services/api";
import { useAuth } from "../contexts/AuthContext";

type UserRow = { id: number; email: string; full_name?: string; created_at?: string; status?: string; };

export default function Admin(){
  const { user, signout } = useAuth();
  const [users, setUsers] = useState<UserRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string|null>(null);
  const [rejectReason, setRejectReason] = useState<string>("");

  useEffect(() => {
    const load = async () => {
      try {
        const res = await api.get("/admin/users", { status: "PENDING", page: 1, page_size: 50 });
        setUsers(res.data);
      } catch (err: any) {
        setError("Failed to load users");
      } finally { setLoading(false); }
    };
    load();
  }, []);

  const approve = async (id: number) => {
    try {
      await api.post(`/admin/users/${id}/approve`);
      setUsers(prev => prev.filter(u => u.id !== id));
    } catch (err) {
      setError("Approve failed");
    }
  };

  const reject = async (id: number) => {
    try {
      await api.post(`/admin/users/${id}/reject`, { status: "REJECTED", rejection_reason: rejectReason });
      setUsers(prev => prev.filter(u => u.id !== id));
      setRejectReason("");
    } catch (err) {
      setError("Reject failed");
    }
  };

  if (loading) return <div className="container">Loading...</div>;

  return (
    <div className="container">
      <h2>Admin - Pending Users</h2>
      <button onClick={signout} style={{float:"right"}}>Logout</button>
      {error && <div className="error">{error}</div>}
      <table className="table">
        <thead><tr><th>Name</th><th>Email</th><th>Registered</th><th>Status</th><th>Actions</th></tr></thead>
        <tbody>
          {users.map(u => (
            <tr key={u.id}>
              <td>{u.full_name}</td>
              <td>{u.email}</td>
              <td>{new Date(u.created_at).toLocaleString()}</td>
              <td>{u.status}</td>
              <td>
                <button onClick={() => approve(u.id)}>Approve</button>
                <button onClick={() => {
                  const reason = prompt("Rejection reason:");
                  if (reason !== null) {
                    api.post(`/admin/users/${u.id}/reject`, { status: "REJECTED", rejection_reason: reason })
                      .then(() => setUsers(prev => prev.filter(x=>x.id!==u.id)))
                      .catch(()=> setError("Reject failed"));
                  }
                }}>Reject</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
