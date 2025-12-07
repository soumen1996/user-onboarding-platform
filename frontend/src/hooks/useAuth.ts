import { useState, useEffect } from 'react';
import { useContext } from 'react';
import { AuthContext } from '../context/AuthContext';
import { api } from '../services/api';

const useAuth = () => {
    const { setAuth } = useContext(AuthContext);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const checkAuth = async () => {
            try {
                const response = await api.get('/auth/check'); // Adjust the endpoint as necessary
                setAuth(response.data);
            } catch (err) {
                setError(err);
            } finally {
                setLoading(false);
            }
        };

        checkAuth();
    }, [setAuth]);

    const login = async (credentials) => {
        try {
            const response = await api.post('/auth/login', credentials);
            setAuth(response.data);
        } catch (err) {
            setError(err);
        }
    };

    const logout = async () => {
        try {
            await api.post('/auth/logout');
            setAuth(null);
        } catch (err) {
            setError(err);
        }
    };

    return { loading, error, login, logout };
};

export default useAuth;