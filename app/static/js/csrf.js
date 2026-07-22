/**
 * CSRF token helper for forms and AJAX requests.
 * Reads the csrf_token from cookie and adds to X-CSRF-Token header.
 */

function getCsrfToken() {
    const match = document.cookie.match(/csrf_token=([^;]+)/);
    if (match) return decodeURIComponent(match[1]);
    return null;
}

// Add CSRF token to all fetch requests
const originalFetch = window.fetch;
window.fetch = function(url, options = {}) {
    const token = getCsrfToken();
    if (token) {
        options.headers = options.headers || {};
        options.headers['X-CSRF-Token'] = token;
    }
    return originalFetch.call(this, url, options);
};

// Add CSRF token to all XMLHttpRequest
const originalXHROpen = XMLHttpRequest.prototype.open;
const originalXHRSend = XMLHttpRequest.prototype.send;

XMLHttpRequest.prototype.open = function(method, url, ...args) {
    this._csrfMethod = method;
    return originalXHROpen.call(this, method, url, ...args);
};

XMLHttpRequest.prototype.send = function(data) {
    if (this._csrfMethod && this._csrfMethod.toUpperCase() !== 'GET') {
        const token = getCsrfToken();
        if (token) {
            this.setRequestHeader('X-CSRF-Token', token);
        }
    }
    return originalXHRSend.call(this, data);
};

// Add CSRF token to form submissions via JavaScript
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('form[method="post"], form[method="POST"]').forEach(function(form) {
        form.addEventListener('submit', function(e) {
            const token = getCsrfToken();
            if (token) {
                // Add hidden input if not present
                let input = form.querySelector('input[name="csrf_token"]');
                if (!input) {
                    input = document.createElement('input');
                    input.type = 'hidden';
                    input.name = 'csrf_token';
                    form.appendChild(input);
                }
                input.value = token;
            }
        });
    });
});
