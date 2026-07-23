/**
 * WebSocket client for DWMB real-time notifications.
 * 
 * Usage:
 *   const ws = new DWMBWebSocket();
 *   ws.connect();
 *   ws.on('entity_created', (data) => { console.log(data); });
 */
class DWMBWebSocket {
    constructor(url = null) {
        this.url = url || this._getUrl();
        this.ws = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 10;
        this.reconnectDelay = 1000;
        this.handlers = {};
        this.connected = false;
    }
    
    _getUrl() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const token = this._getToken();
        return `${protocol}//${window.location.host}/ws${token ? '?token=' + token : ''}`;
    }
    
    _getToken() {
        const match = document.cookie.match(/access_token=([^;]+)/);
        return match ? match[1] : null;
    }
    
    connect() {
        try {
            this.ws = new WebSocket(this.url);
            
            this.ws.onopen = () => {
                console.log('WebSocket connected');
                this.connected = true;
                this.reconnectAttempts = 0;
                this._emit('connected');
            };
            
            this.ws.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    this._emit(data.type, data);
                } catch (e) {
                    console.error('WebSocket message parse error:', e);
                }
            };
            
            this.ws.onclose = () => {
                console.log('WebSocket disconnected');
                this.connected = false;
                this._emit('disconnected');
                this._reconnect();
            };
            
            this.ws.onerror = (error) => {
                console.error('WebSocket error:', error);
                this._emit('error', error);
            };
        } catch (e) {
            console.error('WebSocket connection error:', e);
            this._reconnect();
        }
    }
    
    _reconnect() {
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
            this.reconnectAttempts++;
            const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);
            console.log(`Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);
            setTimeout(() => this.connect(), delay);
        }
    }
    
    send(data) {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify(data));
        }
    }
    
    ping() {
        this.send({ type: 'ping' });
    }
    
    subscribe(channel) {
        this.send({ type: 'subscribe', channel });
    }
    
    unsubscribe(channel) {
        this.send({ type: 'unsubscribe', channel });
    }
    
    on(event, handler) {
        if (!this.handlers[event]) {
            this.handlers[event] = [];
        }
        this.handlers[event].push(handler);
    }
    
    off(event, handler) {
        if (this.handlers[event]) {
            this.handlers[event] = this.handlers[event].filter(h => h !== handler);
        }
    }
    
    _emit(event, data) {
        if (this.handlers[event]) {
            this.handlers[event].forEach(handler => handler(data));
        }
    }
    
    disconnect() {
        if (this.ws) {
            this.ws.close();
        }
    }
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = DWMBWebSocket;
}
