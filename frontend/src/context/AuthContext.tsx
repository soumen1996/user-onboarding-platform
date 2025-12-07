import React, { createContext, useContext, useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import jwtDecode from 'jwt-decode';

interface AuthContextType {
  user: any;
  login: (token: string) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<any>(null);
  const navigate = useNavigate();

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (token) {
      const decoded: any = jwtDecode(token);
      setUser(decoded);
    }
  }, []);

  const login = (token: string) => {
    localStorage.setItem('token', token);
    const decoded: any = jwtDecode(token);
    setUser(decoded);
    navigate('/'); // Redirect to home or desired page after login
  };

  const logout = () => {
    localStorage.removeItem('token');
    setUser(null);
    navigate('/login'); // Redirect to login page after logout
  };

  return (
    <AuthContext.Provider value={{ user, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};