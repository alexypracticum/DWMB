/**
 * GraphQL subscriptions client for real-time updates.
 * Uses WebSocket transport (graphql-transport-ws protocol).
 */
class GraphQLSubscriptions {
    constructor(url = 'ws://' + window.location.host + '/graphql') {
        this.url = url;
        this.ws = null;
        this.subscriptions = new Map();
        this.connected = false;
        this.reconnectDelay = 1000;
        this.maxReconnectDelay = 30000;
        this.subscriptionIdCounter = 0;
    }

    connect() {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) return;

        this.ws = new WebSocket(this.url, 'graphql-transport-ws');

        this.ws.onopen = () => {
            console.log('[GraphQL Sub] Connected');
        };

        this.ws.onmessage = (event) => {
            const message = JSON.parse(event.data);

            switch (message.type) {
                case 'connection_ack':
                    this.connected = true;
                    this.reconnectDelay = 1000;
                    console.log('[GraphQL Sub] Connection acknowledged');
                    // Re-subscribe after reconnect
                    this._resubscribe();
                    break;

                case 'next':
                    const handler = this.subscriptions.get(message.id);
                    if (handler) {
                        handler(message.payload.data);
                    }
                    break;

                case 'error':
                    console.error('[GraphQL Sub] Error:', message.payload);
                    break;

                case 'complete':
                    this.subscriptions.delete(message.id);
                    break;
            }
        };

        this.ws.onclose = () => {
            this.connected = false;
            console.log('[GraphQL Sub] Disconnected, reconnecting in', this.reconnectDelay, 'ms');
            setTimeout(() => this.connect(), this.reconnectDelay);
            this.reconnectDelay = Math.min(this.reconnectDelay * 2, this.maxReconnectDelay);
        };

        this.ws.onerror = (error) => {
            console.error('[GraphQL Sub] WebSocket error:', error);
        };
    }

    subscribe(query, variables, onData) {
        if (!this.connected) {
            console.warn('[GraphQL Sub] Not connected, queuing subscription');
        }

        const id = String(++this.subscriptionIdCounter);

        // Store subscription info for re-subscription
        this.subscriptions.set(id, onData);
        this.subscriptions.set(id + '_query', query);
        this.subscriptions.set(id + '_variables', variables);

        // Send connection_init if not connected
        if (this.ws.readyState === WebSocket.OPEN && !this.connected) {
            this.ws.send(JSON.stringify({ type: 'connection_init' }));
        }

        // Send subscription
        this.ws.send(JSON.stringify({
            id,
            type: 'start',
            payload: { query, variables },
        }));

        return id;
    }

    unsubscribe(id) {
        if (this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify({ id, type: 'stop' }));
        }
        this.subscriptions.delete(id);
        this.subscriptions.delete(id + '_query');
        this.subscriptions.delete(id + '_variables');
    }

    _resubscribe() {
        for (const [id, handler] of this.subscriptions) {
            if (id.endsWith('_query') || id.endsWith('_variables')) continue;
            const query = this.subscriptions.get(id + '_query');
            const variables = this.subscriptions.get(id + '_variables');
            if (query) {
                this.ws.send(JSON.stringify({
                    id,
                    type: 'start',
                    payload: { query, variables },
                }));
            }
        }
    }

    disconnect() {
        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }
        this.connected = false;
        this.subscriptions.clear();
    }
}

// Singleton instance
const graphqlSub = new GraphQLSubscriptions();

// Auto-connect when page loads
document.addEventListener('DOMContentLoaded', () => {
    graphqlSub.connect();
});

// Disconnect when page unloads
window.addEventListener('beforeunload', () => {
    graphqlSub.disconnect();
});
