const API_BASE_URL = 'http://127.0.0.1:8000';

class ApiClient {
    static getTokens() {
        const access = localStorage.getItem('access_token');
        const refresh = localStorage.getItem('refresh_token');
        return { access, refresh };
    }

    static saveTokens(access, refresh) {
        if (access) localStorage.setItem('access_token', access);
        if (refresh) localStorage.setItem('refresh_token', refresh);
    }

    static saveUser(user) {
        localStorage.setItem('user', JSON.stringify(user));
    }

    static getUser() {
        const userStr = localStorage.getItem('user');
        try {
            return userStr ? JSON.parse(userStr) : null;
        } catch {
            return null;
        }
    }

    static clearAuth() {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        localStorage.removeItem('user');
    }

    static decodeJwt(token) {
        try {
            const base64Url = token.split('.')[1];
            const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
            const jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
                return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
            }).join(''));
            return JSON.parse(jsonPayload);
        } catch (e) {
            return null;
        }
    }

    static isTokenExpired(token) {
        if (!token) return true;
        const decoded = this.decodeJwt(token);
        if (!decoded || !decoded.exp) return true;
        
        // Check if token is expired or expires in the next 30 seconds
        const currentTime = Math.floor(Date.now() / 1000);
        return decoded.exp < (currentTime + 30);
    }

    static async refreshToken() {
        const { refresh } = this.getTokens();
        if (!refresh) {
            this.clearAuth();
            throw new Error('No refresh token available');
        }

        try {
            const res = await fetch(`${API_BASE_URL}/api/accounts/token/refresh/`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ refresh })
            });

            if (!res.ok) {
                this.clearAuth();
                throw new Error('Refresh token expired or invalid');
            }

            const data = await res.json();
            this.saveTokens(data.access);
            return data.access;
        } catch (e) {
            this.clearAuth();
            throw e;
        }
    }

    static async request(endpoint, options = {}) {
        let { access } = this.getTokens();

        // 1. Check if token needs to be refreshed before making the request
        if (access && this.isTokenExpired(access)) {
            try {
                access = await this.refreshToken();
            } catch (e) {
                // Token refresh failed, redirect to login page (handled by router event)
                window.dispatchEvent(new CustomEvent('auth-expired'));
                throw new Error('Session expired, please login again.');
            }
        }

        options.headers = options.headers || {};
        if (access) {
            options.headers['Authorization'] = `Bearer ${access}`;
        }
        
        if (!(options.body instanceof FormData) && options.body && typeof options.body === 'object') {
            options.headers['Content-Type'] = 'application/json';
            options.body = JSON.stringify(options.body);
        }

        let response = await fetch(`${API_BASE_URL}${endpoint}`, options);

        // 2. Intercept 401 Unauthorized (just in case)
        if (response.status === 401) {
            try {
                access = await this.refreshToken();
                options.headers['Authorization'] = `Bearer ${access}`;
                response = await fetch(`${API_BASE_URL}${endpoint}`, options);
            } catch (e) {
                window.dispatchEvent(new CustomEvent('auth-expired'));
                throw new Error('Session expired, please login again.');
            }
        }

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({ detail: 'An unexpected error occurred.' }));
            const err = new Error(errorData.detail || JSON.stringify(errorData));
            err.status = response.status;
            err.data = errorData;
            throw err;
        }

        if (response.status === 204) return null;
        return await response.json();
    }

    // AUTH ENDPOINTS
    static async login(username, password) {
        const data = await this.request('/api/accounts/login/', {
            method: 'POST',
            body: { username, password }
        });
        this.saveTokens(data.access, data.refresh);
        this.saveUser({
            username: username,
            role: data.role,
            is_approved: data.is_approved,
            roll_number: data.roll_number
        });
        return data;
    }

    static async register(userData) {
        return await this.request('/api/accounts/register/', {
            method: 'POST',
            body: userData
        });
    }

    // STUDENT APPROVAL WORKFLOW
    static async getPendingStudents() {
        return await this.request('/api/accounts/students/pending/');
    }

    static async getStudents() {
        return await this.request('/api/accounts/students/');
    }

    static async approveStudent(id) {
        return await this.request(`/api/accounts/students/${id}/approve/`, {
            method: 'POST'
        });
    }

    static async rejectStudent(id) {
        return await this.request(`/api/accounts/students/${id}/reject/`, {
            method: 'POST'
        });
    }

    // ASSIGNMENT CRUD
    static async getAssignments() {
        return await this.request('/api/assignments/');
    }

    static async getAssignment(id) {
        return await this.request(`/api/assignments/${id}/`);
    }

    static async createAssignment(data) {
        return await this.request('/api/assignments/', {
            method: 'POST',
            body: data
        });
    }

    static async updateAssignment(id, data) {
        return await this.request(`/api/assignments/${id}/`, {
            method: 'PATCH',
            body: data
        });
    }

    static async deleteAssignment(id) {
        return await this.request(`/api/assignments/${id}/`, {
            method: 'DELETE'
        });
    }

    // SUBMISSIONS
    static async getSubmissions() {
        return await this.request('/api/submissions/');
    }

    static async createSubmission(data) {
        return await this.request('/api/submissions/', {
            method: 'POST',
            body: data
        });
    }

    static async getPendingSubmissions() {
        return await this.request('/api/submissions/pending/');
    }

    // DASHBOARD ANALYTICS
    static async getDashboardAnalytics() {
        return await this.request('/api/dashboard/analytics/');
    }
}
