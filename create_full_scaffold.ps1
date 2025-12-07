# Creates/updates backend auth/admin/user endpoints, frontend scaffold (React + TypeScript),
# Dockerfiles, docker-compose, .env.example and README.
# Run from repo root:
#   powershell -ExecutionPolicy Bypass -File .\create_full_scaffold.ps1

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
function Write-FileSafely($relPath, $content) {
    $full = Join-Path $root $relPath
    $dir = Split-Path $full -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path $full) {
        $bak = "$full.bak_$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item -Path $full -Destination $bak -Force
        Write-Host "Backed up $relPath -> $(Split-Path $bak -Leaf)"
    }
    $content | Out-File -FilePath $full -Encoding UTF8 -Force
    Write-Host "Wrote $relPath"
}

# Backend files
$backendFiles = @{
"backend/app/api/routers/auth.py" = @'
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from jose import jwt

from ...db.session import get_db
from ...models.user import User
from ...schemas.user import LoginRequest, Token
from ...core.config import settings
from ...core.security import verify_password

router = APIRouter()

@router.post("/auth/login", response_model=Token)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    """
    Authenticate user and return JWT access token with claims: sub (id), email, role.
    """
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode = {"sub": str(user.id), "email": user.email, "role": user.role, "exp": expire}
    token = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return {"access_token": token, "token_type": "bearer"}
'@

"backend/app/api/routers/public.py" = @'
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ...db.session import get_db
from ...models.user import User
from ...schemas.user import UserCreate, UserRead
from ...core.security import hash_password

router = APIRouter()

@router.post("/auth/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def register(payload: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new user. Sets role="USER", status="PENDING".
    Validates password length >= 8 and unique email.
    """
    # pydantic EmailStr validates format; enforce password length here as additional guard
    if len(payload.password) < 8:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Password must be at least 8 characters")
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")
    user = User(
        email=payload.email,
        password_hash=hash_password(payload.password),
        full_name=payload.full_name,
        role="USER",
        status="PENDING"
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
'@

"backend/app/api/routers/user.py" = @'
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ...db.session import get_db
from ...schemas.user import UserRead, UserStatus
from ...core.security import get_current_user

router = APIRouter()

@router.get("/me", response_model=UserRead)
def read_me(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Return current authenticated user (UserRead).
    """
    return current_user

@router.get("/me/status", response_model=UserStatus)
def read_my_status(current_user=Depends(get_current_user)):
    """
    Return only status and rejection_reason for current authenticated user.
    """
    return {"status": current_user.status, "rejection_reason": current_user.rejection_reason}
'@

"backend/app/api/routers/admin.py" = @'
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional, Tuple

from ...db.session import get_db
from ...models.user import User
from ...schemas.user import UserRead, UserUpdateStatus, UserStatus
from ...core.security import get_current_admin_user

router = APIRouter()

@router.get("/admin/users", response_model=List[UserRead])
def list_users(status: Optional[str] = "PENDING", page: int = 1, page_size: int = 20, db: Session = Depends(get_db), current_admin=Depends(get_current_admin_user)):
    """
    Paginated list of users by status. Returns list (page) - total count can be retrieved separately if needed.
    """
    if page < 1:
        page = 1
    if page_size < 1 or page_size > 200:
        page_size = 20
    query = db.query(User).filter(User.status == status)
    users = query.offset((page-1)*page_size).limit(page_size).all()
    return users

@router.post("/admin/users/{user_id}/approve", response_model=UserRead)
def approve_user(user_id: int, db: Session = Depends(get_db), current_admin=Depends(get_current_admin_user)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if user.status != "PENDING":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User status is not PENDING")
    user.status = "APPROVED"
    user.rejection_reason = None
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.post("/admin/users/{user_id}/reject", response_model=UserRead)
def reject_user(user_id: int, payload: UserUpdateStatus = Depends(), db: Session = Depends(get_db), current_admin=Depends(get_current_admin_user)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if user.status != "PENDING":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User status is not PENDING")
    if payload.status != "REJECTED":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid status for rejection")
    user.status = "REJECTED"
    user.rejection_reason = payload.rejection_reason
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
'@

"backend/app/api/routers/__init__.py" = @'
from . import users
from . import auth
from . import public
from . import user
from . import admin
'@

"backend/app/main.py" = @'
from fastapi import FastAPI
from .api.routers import users, auth, public, user, admin

def create_app() -> FastAPI:
    app = FastAPI(title="Onboarding API")

    @app.get("/health", tags=["health"])
    async def health():
        return {"status": "ok"}

    # include routers under /api/v1
    app.include_router(users.router, prefix="/api/v1", tags=["users"])
    app.include_router(auth.router, prefix="/api/v1", tags=["auth"])
    app.include_router(public.router, prefix="/api/v1", tags=["public"])
    app.include_router(user.router, prefix="/api/v1", tags=["user"])
    app.include_router(admin.router, prefix="/api/v1", tags=["admin"])
    return app

app = create_app()
'@

"backend/app/core/security.py" = @'
from datetime import datetime, timedelta
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from .config import settings
from ..db.session import get_db
from ..models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    encoded = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return encoded

def _get_user_from_db(db: Session, user_id: int):
    return db.query(User).filter(User.id == user_id).first()

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        user_id = int(payload.get("sub"))
        if user_id is None:
            raise credentials_exception
    except (JWTError, ValueError):
        raise credentials_exception
    user = _get_user_from_db(db, user_id)
    if user is None:
        raise credentials_exception
    return user

def get_current_admin_user(current_user = Depends(get_current_user)):
    if current_user.role != "ADMIN":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin privileges required")
    return current_user
'@

"backend/app/services/user_service.py" = @'
from sqlalchemy.orm import Session
from typing import List, Optional, Tuple
from ..models.user import User
from ..core.security import hash_password

class UserService:
    def __init__(self, db: Session):
        self.db = db

    def create_user(self, email: str, password: str, full_name: Optional[str] = None, role: str = "USER") -> User:
        user = User(email=email, password_hash=hash_password(password), full_name=full_name, role=role, status="PENDING")
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def get_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(User.email == email).first()

    def get_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()

    def list_users_by_status(self, status: str, page: int = 1, page_size: int = 20) -> Tuple[List[User], int]:
        query = self.db.query(User).filter(User.status == status)
        total = query.count()
        results = query.offset((page-1)*page_size).limit(page_size).all()
        return results, total

    def approve(self, user: User) -> User:
        user.status = "APPROVED"
        user.rejection_reason = None
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def reject(self, user: User, reason: Optional[str] = None) -> User:
        user.status = "REJECTED"
        user.rejection_reason = reason
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user
'@

"backend/app/schemas/user.py" = @'
from pydantic import BaseModel, EmailStr, constr
from typing import Optional
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    password: constr(min_length=8)
    full_name: Optional[str] = None

class UserRead(BaseModel):
    id: int
    email: EmailStr
    full_name: Optional[str] = None
    role: str
    status: str
    rejection_reason: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class UserStatus(BaseModel):
    status: str
    rejection_reason: Optional[str] = None

class UserUpdateStatus(BaseModel):
    status: str
    rejection_reason: Optional[str] = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
'@

"backend/app/models/user.py" = @'
from sqlalchemy import Column, Integer, String, DateTime, Text, func
from ..db.base import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=True)
    role = Column(String(20), nullable=False, default="USER")           # "USER" or "ADMIN"
    status = Column(String(20), nullable=False, default="PENDING")      # "PENDING", "APPROVED", "REJECTED"
    rejection_reason = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    def __repr__(self):
        return f"<User id={self.id} email={self.email} role={self.role} status={self.status}>"
'@

"backend/app/db/init_db.py" = @'
from .base import Base
from .session import engine

def create_tables():
    """
    Create tables in the target database. Ensure AZURE_SQL_CONNECTION_STRING is set in the environment.
    Use Alembic for production migrations.
    """
    Base.metadata.create_all(bind=engine)

if __name__ == "__main__":
    create_tables()
    print("Tables created (if they did not already exist).")
'@
}

foreach ($k in $backendFiles.Keys) { Write-FileSafely $k $backendFiles[$k] }

# Frontend scaffold (React + TypeScript)
$frontendFiles = @{
"frontend/package.json" = @'
{
  "name": "onboarding-frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "start": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "axios": "^1.5.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.14.1"
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "vite": "^5.1.0",
    "@types/react": "^18.2.27",
    "@types/react-dom": "^18.2.11",
    "@types/react-router-dom": "^5.3.3"
  }
}
'@

"frontend/tsconfig.json" = @'
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["DOM", "ES2020"],
    "jsx": "react-jsx",
    "module": "ESNext",
    "moduleResolution": "Node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "outDir": "dist"
  },
  "include": ["src"]
}
'@

"frontend/index.html" = @'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Onboarding App</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
'@

"frontend/src/main.tsx" = @'
import React from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import { AuthProvider } from "./contexts/AuthContext";
import "./styles.css";

createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <AuthProvider>
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </AuthProvider>
  </React.StrictMode>
);
'@

"frontend/src/App.tsx" = @'
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
'@

"frontend/src/contexts/AuthContext.tsx" = @'
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
'@

"frontend/src/services/api.ts" = @'
import axios from "axios";

const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000/api/v1";

const instance = axios.create({ baseURL: API_BASE });

let authToken: string | null = null;

const setAuthToken = (token: string) => { authToken = token; instance.defaults.headers.common["Authorization"] = `Bearer ${token}`; };
const clearAuthToken = () => { authToken = null; delete instance.defaults.headers.common["Authorization"]; };

const api = {
  instance,
  setAuthToken,
  clearAuthToken,
  async post(path: string, data?: any) { return instance.post(path, data); },
  async get(path: string, params?: any) { return instance.get(path, { params }); },
  async put(path: string, data?: any) { return instance.put(path, data); },
  async delete(path: string) { return instance.delete(path); }
};

export default api;
'@

"frontend/src/pages/Register.tsx" = @'
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
'@

"frontend/src/pages/Login.tsx" = @'
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
'@

"frontend/src/pages/Me.tsx" = @'
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
'@

"frontend/src/pages/Admin.tsx" = @'
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
'@

"frontend/src/styles.css" = @'
body { font-family: Arial, Helvetica, sans-serif; background:#f6f8fa; margin:0; padding:20px; }
.container { max-width:900px; margin:0 auto; background:#fff; padding:20px; border-radius:6px; box-shadow:0 2px 6px rgba(0,0,0,0.05); }
.form label { display:block; margin-bottom:10px; }
.form input { width:100%; padding:8px; margin-top:4px; box-sizing:border-box; }
button { padding:8px 12px; margin-right:6px; }
.error { color:#b00020; margin-top:10px; }
.success { color:green; margin-top:10px; }
.table { width:100%; border-collapse:collapse; margin-top:10px; }
.table th, .table td { padding:8px 6px; border-bottom:1px solid #eee; text-align:left; }
.status.pending { color:orange; font-weight:bold; }
.status.approved { color:green; font-weight:bold; }
.status.rejected { color:red; font-weight:bold; }
'@

"frontend/README.md" = @'
React + TypeScript frontend scaffold. Use `npm install` then `npm run dev` or `npm start` depending on your setup.
'@
}

foreach ($f in $frontendFiles.Keys) { Write-FileSafely $f $frontendFiles[$f] }

# Docker and docker-compose (root-level)
$infraFiles = @{
"docker-compose.yml" = @'
version: "3.8"
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2019-latest
    container_name: onboarding_sql
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=${SA_PASSWORD}
    ports:
      - "1433:1433"
    healthcheck:
      test: [ "CMD", "/opt/mssql-tools/bin/sqlcmd", "-S", "localhost", "-U", "sa", "-P", "${SA_PASSWORD}", "-Q", "SELECT 1" ]
      interval: 10s
      timeout: 5s
      retries: 10
    volumes:
      - mssqldata:/var/opt/mssql

  backend:
    build: ./backend
    container_name: onboarding_backend
    depends_on:
      - sqlserver
    environment:
      - AZURE_SQL_CONNECTION_STRING=${AZURE_SQL_CONNECTION_STRING}
      - JWT_SECRET_KEY=${JWT_SECRET_KEY}
      - JWT_ALGORITHM=${JWT_ALGORITHM}
      - ACCESS_TOKEN_EXPIRE_MINUTES=${ACCESS_TOKEN_EXPIRE_MINUTES}
    ports:
      - "8000:8000"

  frontend:
    build: ./frontend
    container_name: onboarding_frontend
    depends_on:
      - backend
    environment:
      - VITE_API_BASE_URL=${VITE_API_BASE_URL}
    ports:
      - "3000:3000"

volumes:
  mssqldata:
'@

"backend/Dockerfile" = @'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN apt-get update && apt-get install -y --no-install-recommends build-essential unixodbc-dev gcc g++ ca-certificates && \
    pip install --no-cache-dir -r /app/requirements.txt && \
    apt-get remove -y build-essential gcc g++ && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

COPY ./app /app/app

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
'@

"frontend/Dockerfile" = @'
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install
COPY . .
RUN npm run build

# serve with a lightweight static server
FROM node:20-alpine
WORKDIR /app
RUN npm install -g serve
COPY --from=build /app/dist /app/dist
EXPOSE 3000
CMD ["serve", "-s", "dist", "-l", "3000"]
'@

".env.example" = @'
# Backend
AZURE_SQL_CONNECTION_STRING= # e.g. mssql+pyodbc:///?odbc_connect=<urlencoded-odbc-string>  (do NOT hardcode secrets in repo)
JWT_SECRET_KEY=your_jwt_secret
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# SQL Server (for local docker-compose)
SA_PASSWORD=YourStrong!Passw0rd

# Frontend
VITE_API_BASE_URL=http://localhost:8000/api/v1
'@

"README.md" = @'
# User Onboarding & Approval Platform

Overview
- Backend: FastAPI (Python) with JWT auth, roles (USER, ADMIN), Azure SQL via SQLAlchemy.
- Frontend: React + TypeScript, client-side auth, pages for register/login, user status and admin dashboard.
- Infra: Docker + docker-compose (backend, frontend, sqlserver for local dev).

Running locally (docker-compose)
1. Copy .env.example -> .env and fill required values (do NOT commit .env).
2. Start:
   docker-compose up --build

Running backend locally (without docker)
1. cd backend
2. python -m venv .venv
3. .\\.venv\\Scripts\\Activate.ps1
4. pip install -r requirements.txt
5. set env vars (AZURE_SQL_CONNECTION_STRING, JWT_SECRET_KEY, ...)
6. python -c "from app.db.init_db import create_tables; create_tables()"
7. uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

Default admin seeding
- This scaffold does not auto-seed admin user with credentials (do not store secrets in repo).
- Create an admin manually in dev:
  python - <<PY
  from app.db.session import SessionLocal
  from app.core.security import hash_password
  from app.models.user import User
  db = SessionLocal()
  admin = User(email="admin@example.com", password_hash=hash_password("ChangeMe123!"), full_name="Admin", role="ADMIN", status="APPROVED")
  db.add(admin); db.commit(); db.close()
  PY

Key API endpoints
- POST /api/v1/auth/register  -> Register user (creates USER with status=PENDING)
- POST /api/v1/auth/login     -> Login, returns JWT
- GET /api/v1/me              -> Current user details (requires auth)
- GET /api/v1/me/status       -> Current user status
- GET /api/v1/admin/users     -> Admin list users by status (requires ADMIN)
- POST /api/v1/admin/users/{id}/approve -> Approve user (ADMIN only)
- POST /api/v1/admin/users/{id}/reject  -> Reject user (ADMIN only)

TODOs / production improvements
- Use Alembic for migrations (do not use create_all in prod).
- Secure secret management (Azure Key Vault / environment variables in CI).
- Add logging, structured errors, request validation limits, rate-limiting.
- Add unit/integration tests and CI pipeline.
- Harden CORS, HTTPS, cookie/session policies for frontend.
'@
}

foreach ($n in $infraFiles.Keys) { Write-FileSafely $n $infraFiles[$n] }

Write-Host ""
Write-Host "ALL FILES WRITTEN."
Write-Host "Next steps (recommended):"
Write-Host "1) Inspect generated files, remove backups if not needed."
Write-Host "2) Backend: create venv, install deps:"
Write-Host "   cd backend"
Write-Host "   python -m venv .venv"
Write-Host "   .\\.venv\\Scripts\\Activate.ps1"
Write-Host "   pip install -r requirements.txt"
Write-Host "3) Set env vars (or create backend/.env from .env.example), then create tables:"
Write-Host '   python -c "from app.db.init_db import create_tables; create_tables()"'
Write-Host "4) Start server:"
Write-Host "   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
Write-Host "5) Frontend: cd frontend; npm install; npm run dev or build"
Write-Host ""
Write-Host "Reminder: DO NOT commit real secrets. Add .env to .gitignore."