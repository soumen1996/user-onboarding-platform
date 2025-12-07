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
