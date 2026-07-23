"""
WebSocket manager for real-time notifications.
Handles connections, broadcasting, and message routing.
"""
import logging
import json
from typing import Dict, Set, Optional
from fastapi import WebSocket, WebSocketDisconnect
from datetime import datetime

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manages WebSocket connections and broadcasting."""
    
    def __init__(self):
        # Active connections: user_id -> set of WebSocket connections
        self.active_connections: Dict[str, Set[WebSocket]] = {}
        # All connections (for broadcasting to everyone)
        self.all_connections: Set[WebSocket] = set()
    
    async def connect(self, websocket: WebSocket, user_id: Optional[str] = None):
        """Accept a new WebSocket connection."""
        await websocket.accept()
        self.all_connections.add(websocket)
        
        if user_id:
            if user_id not in self.active_connections:
                self.active_connections[user_id] = set()
            self.active_connections[user_id].add(websocket)
        
        logger.info(f"WebSocket connected: user={user_id}, total={len(self.all_connections)}")
    
    def disconnect(self, websocket: WebSocket, user_id: Optional[str] = None):
        """Remove a WebSocket connection."""
        self.all_connections.discard(websocket)
        
        if user_id and user_id in self.active_connections:
            self.active_connections[user_id].discard(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        
        logger.info(f"WebSocket disconnected: user={user_id}, total={len(self.all_connections)}")
    
    async def broadcast(self, message: dict, exclude: Optional[WebSocket] = None):
        """Broadcast a message to all connected clients."""
        data = json.dumps(message, default=str)
        disconnected = set()
        
        for connection in self.all_connections:
            if connection != exclude:
                try:
                    await connection.send_text(data)
                except Exception:
                    disconnected.add(connection)
        
        # Clean up disconnected
        for conn in disconnected:
            self.all_connections.discard(conn)
    
    async def send_to_user(self, user_id: str, message: dict):
        """Send a message to a specific user."""
        if user_id not in self.active_connections:
            return
        
        data = json.dumps(message, default=str)
        disconnected = set()
        
        for connection in self.active_connections[user_id]:
            try:
                await connection.send_text(data)
            except Exception:
                disconnected.add(connection)
        
        # Clean up disconnected
        for conn in disconnected:
            self.active_connections[user_id].discard(conn)
    
    async def notify_entity_created(self, entity_data: dict):
        """Notify all clients about a new entity."""
        await self.broadcast({
            "type": "entity_created",
            "data": entity_data,
            "timestamp": datetime.utcnow().isoformat()
        })
    
    async def notify_entity_updated(self, entity_data: dict):
        """Notify all clients about an entity update."""
        await self.broadcast({
            "type": "entity_updated",
            "data": entity_data,
            "timestamp": datetime.utcnow().isoformat()
        })
    
    async def notify_entity_deleted(self, entity_id: str):
        """Notify all clients about an entity deletion."""
        await self.broadcast({
            "type": "entity_deleted",
            "data": {"entity_id": entity_id},
            "timestamp": datetime.utcnow().isoformat()
        })
    
    async def notify_comment_added(self, comment_data: dict):
        """Notify all clients about a new comment."""
        await self.broadcast({
            "type": "comment_added",
            "data": comment_data,
            "timestamp": datetime.utcnow().isoformat()
        })
    
    def get_connection_count(self) -> int:
        """Get the number of active connections."""
        return len(self.all_connections)
    
    def get_user_connection_count(self, user_id: str) -> int:
        """Get the number of connections for a specific user."""
        return len(self.active_connections.get(user_id, set()))


# Global connection manager instance
manager = ConnectionManager()
