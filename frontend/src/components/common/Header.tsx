import React from 'react';

const Header: React.FC = () => {
    return (
        <header>
            <h1>User Onboarding Platform</h1>
            <nav>
                <ul>
                    <li><a href="/">Home</a></li>
                    <li><a href="/onboarding">Onboarding</a></li>
                    <li><a href="/admin">Admin</a></li>
                </ul>
            </nav>
        </header>
    );
};

export default Header;