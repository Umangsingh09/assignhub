// App State
const state = {
    user: null,
    activeView: 'login',
    activeModal: null,
    // Temporary variables for modals
    submittingAssignmentId: null,
    editingAssignmentId: null
};

// Toast Notifications Helper
function showToast(message, type = 'success') {
    const alertId = `toast-${Date.now()}`;
    const alertHtml = `
        <div id="${alertId}" class="alert alert-${type === 'success' ? 'success' : 'error'}">
            <span>${type === 'success' ? '✅' : '❌'}</span>
            <div>${message}</div>
        </div>
    `;
    
    // Insert toast container if not exists
    let toastContainer = document.getElementById('toast-container');
    if (!toastContainer) {
        toastContainer = document.createElement('div');
        toastContainer.id = 'toast-container';
        toastContainer.style.position = 'fixed';
        toastContainer.style.bottom = '20px';
        toastContainer.style.right = '20px';
        toastContainer.style.zIndex = '9999';
        toastContainer.style.width = '350px';
        document.body.appendChild(toastContainer);
    }
    
    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = alertHtml;
    const alertEl = tempDiv.firstElementChild;
    toastContainer.appendChild(alertEl);
    
    // Auto remove after 4 seconds
    setTimeout(() => {
        alertEl.style.transition = 'opacity 0.5s ease-out';
        alertEl.style.opacity = '0';
        setTimeout(() => alertEl.remove(), 500);
    }, 400);
}

// Check auth state and update UI
function checkAuth() {
    const user = ApiClient.getUser();
    state.user = user;
    
    const navBar = document.getElementById('nav-bar');
    const navUser = document.getElementById('nav-user-info');
    
    if (user) {
        navBar.classList.remove('d-none');
        navUser.innerHTML = `
            <span class="text-secondary" style="font-size: 0.9rem;">Hello, <strong>${user.username}</strong></span>
            <span class="user-badge">${user.role}</span>
        `;
        
        // Show/hide navigation tabs based on role
        const adminLinks = document.querySelectorAll('.admin-nav');
        const studentLinks = document.querySelectorAll('.student-nav');
        
        if (user.role === 'admin') {
            adminLinks.forEach(el => el.classList.remove('d-none'));
            studentLinks.forEach(el => el.classList.add('d-none'));
        } else {
            adminLinks.forEach(el => el.classList.add('d-none'));
            studentLinks.forEach(el => el.classList.remove('d-none'));
        }
    } else {
        navBar.classList.add('d-none');
    }
}

// Router function mapping hash to views
async function router() {
    checkAuth();
    const hash = window.location.hash || '#login';
    
    // If not authenticated, redirect to login or register
    if (!state.user && hash !== '#login' && hash !== '#register') {
        window.location.hash = '#login';
        return;
    }
    
    // If authenticated, prevent landing on login/register
    if (state.user) {
        if (hash === '#login' || hash === '#register') {
            if (state.user.role === 'admin') {
                window.location.hash = '#admin-dashboard';
            } else if (!state.user.is_approved) {
                window.location.hash = '#pending';
            } else {
                window.location.hash = '#student-dashboard';
            }
            return;
        }
        
        // If student is unapproved, force pending view
        if (state.user.role === 'student' && !state.user.is_approved && hash !== '#pending') {
            window.location.hash = '#pending';
            return;
        }
        
        // Block students from admin-only hashes
        if (state.user.role === 'student' && hash === '#admin-dashboard') {
            window.location.hash = '#student-dashboard';
            return;
        }
        // Block admins from student hashes
        if (state.user.role === 'admin' && (hash === '#student-dashboard' || hash === '#pending')) {
            window.location.hash = '#admin-dashboard';
            return;
        }
    }

    // Hide all views first
    document.querySelectorAll('.app-view').forEach(view => view.classList.add('d-none'));
    
    // Remove active class from nav links
    document.querySelectorAll('.nav-link').forEach(link => link.classList.remove('active'));

    // Activate current view and load data
    if (hash === '#login') {
        document.getElementById('view-login').classList.remove('d-none');
    } else if (hash === '#register') {
        document.getElementById('view-register').classList.remove('d-none');
    } else if (hash === '#pending') {
        document.getElementById('view-pending').classList.remove('d-none');
        // Add active nav indicator if relevant
    } else if (hash === '#student-dashboard') {
        document.getElementById('view-student-dashboard').classList.remove('d-none');
        document.getElementById('nav-student-dash').classList.add('active');
        await loadStudentDashboard();
    } else if (hash === '#admin-dashboard') {
        document.getElementById('view-admin-dashboard').classList.remove('d-none');
        document.getElementById('nav-admin-dash').classList.add('active');
        await loadAdminDashboard();
    }
}

// -------------------------------------------------------------
// STUDENT VIEW SETUP
// -------------------------------------------------------------
async function loadStudentDashboard() {
    try {
        const assignments = await ApiClient.getAssignments();
        const submissions = await ApiClient.getSubmissions();
        
        // Map submissions by assignment ID for quick lookup
        const submissionMap = {};
        submissions.forEach(sub => {
            submissionMap[sub.assignment] = sub;
        });

        // 1. Render Assignments List
        const listContainer = document.getElementById('student-assignments-list');
        if (assignments.length === 0) {
            listContainer.innerHTML = `<div class="text-secondary" style="padding: 2rem; text-align: center;">No assignments available yet.</div>`;
        } else {
            listContainer.innerHTML = assignments.map(a => {
                const sub = submissionMap[a.id];
                let actionBtnHtml = '';
                
                if (sub) {
                    const statusClass = sub.status === 'graded' ? 'badge-graded' : (sub.status === 'late' ? 'badge-late' : 'badge-pending');
                    actionBtnHtml = `<span class="badge ${statusClass}">Submitted (${sub.status})</span>`;
                } else {
                    const isPassed = new Date(a.deadline) < new Date();
                    actionBtnHtml = `
                        <button class="btn btn-primary btn-sm" onclick="openSubmitModal(${a.id}, '${a.title.replace(/'/g, "\\'")}')" ${isPassed ? 'style="opacity: 0.6;"' : ''}>
                            Submit Solution ${isPassed ? '(Late)' : ''}
                        </button>
                    `;
                }

                return `
                    <div class="assignment-card">
                        <div class="assignment-header">
                            <h3 class="assignment-name">${a.title}</h3>
                            ${actionBtnHtml}
                        </div>
                        <p class="assignment-desc">${a.description}</p>
                        <div class="assignment-meta">
                            <span>📅 Deadline: ${new Date(a.deadline).toLocaleString()}</span>
                            ${a.pdf_url ? `<span>📄 <a href="${a.pdf_url}" target="_blank" class="meta-link">Assignment PDF</a></span>` : ''}
                            ${a.external_link ? `<span>🔗 <a href="${a.external_link}" target="_blank" class="meta-link">External Link</a></span>` : ''}
                        </div>
                    </div>
                `;
            }).join('');
        }

        // 2. Render Submissions History
        const subTableBody = document.getElementById('student-submissions-tbody');
        if (submissions.length === 0) {
            subTableBody.innerHTML = `<tr><td colspan="4" style="text-align: center;" class="text-secondary">No submissions recorded.</td></tr>`;
        } else {
            subTableBody.innerHTML = submissions.map(s => {
                const statusClass = s.status === 'graded' ? 'badge-graded' : (s.status === 'late' ? 'badge-late' : 'badge-pending');
                return `
                    <tr>
                        <td><strong>${s.assignment_title}</strong></td>
                        <td>${new Date(s.submitted_at).toLocaleString()}</td>
                        <td><span class="badge ${statusClass}">${s.status}</span></td>
                        <td>
                            ${s.file_url ? `<a href="${s.file_url}" target="_blank" class="meta-link" style="margin-right: 1rem;">View File</a>` : ''}
                            ${s.text_submission ? `<span class="text-secondary" style="font-size: 0.85rem;" title="${s.text_submission.replace(/"/g, '&quot;')}">View Text</span>` : '-'}
                        </td>
                    </tr>
                `;
            }).join('');
        }

    } catch (e) {
        showToast(`Failed to load student dashboard: ${e.message}`, 'error');
    }
}

// -------------------------------------------------------------
// ADMIN VIEW SETUP
// -------------------------------------------------------------
async function loadAdminDashboard() {
    try {
        // Fetch analytics
        const analytics = await ApiClient.getDashboardAnalytics();
        
        // Populate analytics metrics
        document.getElementById('metric-students').innerText = analytics.total_students;
        document.getElementById('metric-pending').innerText = analytics.pending_approvals;
        document.getElementById('metric-assignments').innerText = analytics.total_assignments;
        document.getElementById('metric-submissions').innerText = analytics.total_submissions;
        document.getElementById('metric-completion').innerText = `${analytics.completion_percentage.toFixed(1)}%`;
        document.getElementById('metric-late').innerText = analytics.late_submissions;

        // Fetch students & approvals
        const pendingStudents = await ApiClient.getPendingStudents();
        const assignments = await ApiClient.getAssignments();
        const submissions = await ApiClient.getSubmissions();

        // 1. Render Pending Approvals
        const pendingTbody = document.getElementById('admin-pending-tbody');
        if (pendingStudents.length === 0) {
            pendingTbody.innerHTML = `<tr><td colspan="4" style="text-align: center;" class="text-secondary">No pending approvals.</td></tr>`;
        } else {
            pendingTbody.innerHTML = pendingStudents.map(s => `
                <tr>
                    <td><strong>${s.first_name} ${s.last_name}</strong><br><span class="text-muted">@${s.username}</span></td>
                    <td><code>${s.roll_number}</code></td>
                    <td>${s.email}</td>
                    <td>
                        <button class="btn btn-success btn-sm" onclick="approveStudent(${s.id}, '${s.username}')" style="padding: 0.35rem 0.75rem; margin-right: 0.5rem;">Approve</button>
                        <button class="btn btn-danger btn-sm" onclick="rejectStudent(${s.id}, '${s.username}')" style="padding: 0.35rem 0.75rem;">Reject</button>
                    </td>
                </tr>
            `).join('');
        }

        // 2. Render Assignments CRUD List
        const assignTbody = document.getElementById('admin-assignments-tbody');
        if (assignments.length === 0) {
            assignTbody.innerHTML = `<tr><td colspan="4" style="text-align: center;" class="text-secondary">No assignments created yet.</td></tr>`;
        } else {
            assignTbody.innerHTML = assignments.map(a => `
                <tr>
                    <td><strong>${a.title}</strong></td>
                    <td>${new Date(a.deadline).toLocaleString()}</td>
                    <td>
                        ${a.pdf_url ? `<a href="${a.pdf_url}" target="_blank" class="meta-link" style="margin-right: 1rem;">PDF</a>` : ''}
                        ${a.external_link ? `<a href="${a.external_link}" target="_blank" class="meta-link">Link</a>` : '-'}
                    </td>
                    <td>
                        <button class="btn btn-secondary btn-sm" onclick="openEditAssignmentModal(${a.id})" style="padding: 0.35rem 0.75rem; margin-right: 0.5rem;">Edit</button>
                        <button class="btn btn-danger btn-sm" onclick="deleteAssignment(${a.id})" style="padding: 0.35rem 0.75rem;">Delete</button>
                    </td>
                </tr>
            `).join('');
        }

        // 3. Render Submissions List
        const subTbody = document.getElementById('admin-submissions-tbody');
        if (submissions.length === 0) {
            subTbody.innerHTML = `<tr><td colspan="5" style="text-align: center;" class="text-secondary">No submissions recorded.</td></tr>`;
        } else {
            subTbody.innerHTML = submissions.map(s => {
                const statusClass = s.status === 'graded' ? 'badge-graded' : (s.status === 'late' ? 'badge-late' : 'badge-pending');
                return `
                    <tr>
                        <td><strong>${s.student_username}</strong></td>
                        <td>${s.assignment_title}</td>
                        <td>${new Date(s.submitted_at).toLocaleString()}</td>
                        <td><span class="badge ${statusClass}">${s.status}</span></td>
                        <td>
                            ${s.file_url ? `<a href="${s.file_url}" target="_blank" class="meta-link" style="margin-right: 1rem;">View File</a>` : ''}
                            ${s.text_submission ? `<span class="text-secondary" style="font-size: 0.85rem;" title="${s.text_submission.replace(/"/g, '&quot;')}">View Text</span>` : '-'}
                        </td>
                    </tr>
                `;
            }).join('');
        }

    } catch (e) {
        showToast(`Failed to load admin dashboard: ${e.message}`, 'error');
    }
}

// Student approval action handlers
async function approveStudent(id, username) {
    if (!confirm(`Are you sure you want to approve student @${username}?`)) return;
    try {
        await ApiClient.approveStudent(id);
        showToast(`Student @${username} approved successfully!`);
        await loadAdminDashboard();
    } catch (e) {
        showToast(`Failed to approve student: ${e.message}`, 'error');
    }
}

async function rejectStudent(id, username) {
    if (!confirm(`Are you sure you want to reject and deactivate student @${username}?`)) return;
    try {
        await ApiClient.rejectStudent(id);
        showToast(`Student @${username} rejected and deactivated.`, 'warning');
        await loadAdminDashboard();
    } catch (e) {
        showToast(`Failed to reject student: ${e.message}`, 'error');
    }
}

// Assignment deletion
async function deleteAssignment(id) {
    if (!confirm('Are you sure you want to delete this assignment? All associated student submissions will be deleted!')) return;
    try {
        await ApiClient.deleteAssignment(id);
        showToast('Assignment deleted successfully!');
        await loadAdminDashboard();
    } catch (e) {
        showToast(`Failed to delete assignment: ${e.message}`, 'error');
    }
}

// -------------------------------------------------------------
// MODALS MANAGEMENT
// -------------------------------------------------------------
function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('active');
        state.activeModal = modalId;
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('active');
        state.activeModal = null;
        
        // Reset forms in the modal
        const form = modal.querySelector('form');
        if (form) form.reset();
        
        // Reset file uploads preview labels
        const fileLabel = modal.querySelector('.file-selected-name');
        if (fileLabel) fileLabel.classList.add('d-none');
    }
}

// Student Submit solution modal trigger
window.openSubmitModal = function(assignmentId, title) {
    state.submittingAssignmentId = assignmentId;
    document.getElementById('submit-assignment-title').innerText = title;
    openModal('modal-submit');
};

// Admin Edit assignment modal trigger
window.openEditAssignmentModal = async function(assignmentId) {
    try {
        const assignment = await ApiClient.getAssignment(assignmentId);
        state.editingAssignmentId = assignmentId;
        
        // Pre-fill form values
        document.getElementById('assign-title').value = assignment.title;
        document.getElementById('assign-desc').value = assignment.description;
        document.getElementById('assign-external').value = assignment.external_link || '';
        
        // Format date-time for datetime-local input (YYYY-MM-DDTHH:MM)
        const d = new Date(assignment.deadline);
        const pad = (n) => n.toString().padStart(2, '0');
        const formattedDeadline = `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
        document.getElementById('assign-deadline').value = formattedDeadline;
        
        document.getElementById('modal-assign-title').innerText = 'Edit Assignment';
        openModal('modal-assignment');
    } catch (e) {
        showToast(`Failed to fetch assignment: ${e.message}`, 'error');
    }
};

window.openCreateAssignmentModal = function() {
    state.editingAssignmentId = null;
    document.getElementById('modal-assign-title').innerText = 'Create New Assignment';
    openModal('modal-assignment');
};

// -------------------------------------------------------------
// EVENT LISTENERS INITIALIZATION
// -------------------------------------------------------------
document.addEventListener('DOMContentLoaded', () => {
    // 1. Initial routing triggers
    window.addEventListener('hashchange', router);
    window.addEventListener('load', router);
    
    // JWT expiration event interceptor
    window.addEventListener('auth-expired', () => {
        showToast('Your session has expired. Please login again.', 'error');
        window.location.hash = '#login';
    });

    // 2. Auth Actions (Login/Register/Logout)
    const loginForm = document.getElementById('login-form');
    if (loginForm) {
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const username = loginForm.username.value.trim();
            const password = loginForm.password.value;
            
            const submitBtn = loginForm.querySelector('button[type="submit"]');
            submitBtn.disabled = true;
            submitBtn.innerText = 'Signing in...';

            try {
                const data = await ApiClient.login(username, password);
                showToast(`Welcome back, @${username}!`);
                
                // Re-route based on role/approval status
                if (data.role === 'admin') {
                    window.location.hash = '#admin-dashboard';
                } else if (!data.is_approved) {
                    window.location.hash = '#pending';
                } else {
                    window.location.hash = '#student-dashboard';
                }
            } catch (err) {
                showToast(err.message, 'error');
            } finally {
                submitBtn.disabled = false;
                submitBtn.innerText = 'Sign In';
            }
        });
    }

    const registerForm = document.getElementById('register-form');
    if (registerForm) {
        registerForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const payload = {
                username: registerForm.username.value.trim(),
                email: registerForm.email.value.trim(),
                first_name: registerForm.first_name.value.trim(),
                last_name: registerForm.last_name.value.trim(),
                roll_number: registerForm.roll_number.value.trim(),
                password: registerForm.password.value,
                password2: registerForm.password2.value
            };

            if (payload.password !== payload.password2) {
                showToast('Passwords do not match.', 'error');
                return;
            }

            const submitBtn = registerForm.querySelector('button[type="submit"]');
            submitBtn.disabled = true;
            submitBtn.innerText = 'Registering...';

            try {
                await ApiClient.register(payload);
                showToast('Registration successful! Please sign in.', 'success');
                window.location.hash = '#login';
                registerForm.reset();
            } catch (err) {
                showToast(err.message, 'error');
            } finally {
                submitBtn.disabled = false;
                submitBtn.innerText = 'Register';
            }
        });
    }

    // Logout trigger
    const logoutBtn = document.getElementById('nav-logout');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', (e) => {
            e.preventDefault();
            ApiClient.clearAuth();
            showToast('Signed out successfully.');
            window.location.hash = '#login';
        });
    }

    // Refresh pending student status
    const refreshStatusBtn = document.getElementById('btn-refresh-status');
    if (refreshStatusBtn) {
        refreshStatusBtn.addEventListener('click', async () => {
            // Attempt to refresh access token which includes status claim, or check user profile again
            const tokens = ApiClient.getTokens();
            if (!tokens.refresh) {
                window.location.hash = '#login';
                return;
            }
            
            refreshStatusBtn.disabled = true;
            refreshStatusBtn.innerText = 'Checking...';
            
            try {
                // Re-login / refresh token flow to get the updated status
                const newAccess = await ApiClient.refreshToken();
                const decoded = ApiClient.decodeJwt(newAccess);
                
                // Get the existing state
                const user = ApiClient.getUser();
                if (user && decoded) {
                    user.is_approved = decoded.is_approved;
                    ApiClient.saveUser(user);
                    state.user = user;
                    
                    if (decoded.is_approved) {
                        showToast('Congratulations! Your account has been approved.');
                        window.location.hash = '#student-dashboard';
                    } else {
                        showToast('Account is still pending admin approval.', 'warning');
                    }
                }
            } catch (err) {
                showToast('Check failed. Session might have expired.', 'error');
            } finally {
                refreshStatusBtn.disabled = false;
                refreshStatusBtn.innerText = 'Refresh Status';
            }
        });
    }

    // 3. File Input UI helpers
    document.querySelectorAll('.file-upload-input').forEach(input => {
        input.addEventListener('change', (e) => {
            const fileNameLabel = e.target.closest('.file-upload-wrapper').querySelector('.file-selected-name');
            if (e.target.files && e.target.files[0]) {
                fileNameLabel.innerText = `Selected: ${e.target.files[0].name}`;
                fileNameLabel.classList.remove('d-none');
            } else {
                fileNameLabel.classList.add('d-none');
            }
        });
    });

    // 4. Modal Submission Forms
    const submitSolutionForm = document.getElementById('form-submit-solution');
    if (submitSolutionForm) {
        submitSolutionForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const textVal = submitSolutionForm.text_submission.value.trim();
            const fileInput = submitSolutionForm.submission_file;
            const file = fileInput.files[0];
            
            if (!textVal && !file) {
                showToast('Please provide a text submission or upload a file.', 'error');
                return;
            }

            const submitBtn = submitSolutionForm.querySelector('button[type="submit"]');
            submitBtn.disabled = true;
            submitBtn.innerText = 'Submitting...';

            try {
                let fileUrl = null;
                if (file) {
                    submitBtn.innerText = 'Uploading file to Storage...';
                    fileUrl = await SupabaseStorage.uploadFile('submissions', file);
                }
                
                submitBtn.innerText = 'Saving submission...';
                await ApiClient.createSubmission({
                    assignment: state.submittingAssignmentId,
                    text_submission: textVal || null,
                    file_url: fileUrl
                });

                showToast('Assignment submitted successfully!');
                closeModal('modal-submit');
                await loadStudentDashboard();
            } catch (err) {
                showToast(err.message, 'error');
            } finally {
                submitBtn.disabled = false;
                submitBtn.innerText = 'Submit Solution';
            }
        });
    }

    const assignmentForm = document.getElementById('form-assignment');
    if (assignmentForm) {
        assignmentForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const payload = {
                title: assignmentForm.title.value.trim(),
                description: assignmentForm.description.value.trim(),
                external_link: assignmentForm.external_link.value.trim() || null,
                deadline: new Date(assignmentForm.deadline.value).toISOString()
            };

            const file = assignmentForm.assignment_file.files[0];
            const submitBtn = assignmentForm.querySelector('button[type="submit"]');
            
            submitBtn.disabled = true;
            submitBtn.innerText = 'Saving...';

            try {
                let fileUrl = null;
                if (file) {
                    submitBtn.innerText = 'Uploading PDF...';
                    fileUrl = await SupabaseStorage.uploadFile('assignments', file);
                    payload.pdf_url = fileUrl;
                }

                if (state.editingAssignmentId) {
                    // Update
                    await ApiClient.updateAssignment(state.editingAssignmentId, payload);
                    showToast('Assignment updated successfully!');
                } else {
                    // Create
                    await ApiClient.createAssignment(payload);
                    showToast('Assignment created successfully!');
                }

                closeModal('modal-assignment');
                await loadAdminDashboard();
            } catch (err) {
                showToast(err.message, 'error');
            } finally {
                submitBtn.disabled = false;
                submitBtn.innerText = 'Save Assignment';
            }
        });
    }

    // Attach modal close buttons listeners
    document.querySelectorAll('.modal-close, .btn-modal-cancel').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const modalEl = e.target.closest('.modal-overlay');
            if (modalEl) closeModal(modalEl.id);
        });
    });
});
