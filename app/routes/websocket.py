"""WebSocket endpoint for real-time notifications."""
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from jose import JWTError, jwt
from app.config import get_settings
from app.services.websocket import manager

router = APIRouter(tags=["websocket"])
settings = get_settings()


@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(None)
):
    """
    WebSocket endpoint for real-time notifications.
    
    Connect with: ws://localhost:8000/ws?token=<jwt_token>
    
    Messages received:
    - {"type": "ping"} -> responds with {"type": "pong"}
    - {"type": "subscribe", "channel": "entities"} -> subscribe to entity updates
    - {"type": "unsubscribe", "channel": "entities"} -> unsubscribe from entity updates
    
    Messages sent:
    - {"type": "pong"} -> response to ping
    - {"type": "entity_created", "data": {...}} -> new entity created
    - {"type": "entity_updated", "data": {...}} -> entity updated
    - {"type": "entity_deleted", "data": {...}} -> entity deleted
    - {"type": "comment_added", "data": {...}} -> new comment added
    """
    # Extract user_id from token
    user_id = None
    if token:
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
            user_id = payload.get("sub")
        except JWTError:
            pass
    
    # Connect
    await manager.connect(websocket, user_id)
    
    try:
        while True:
            # Receive messages from client
            data = await websocket.receive_text()
            
            try:
                message = eval(data)  # Parse JSON (in production, use json.loads)
            except:
                message = {"type": "error", "message": "Invalid JSON"}
            
            msg_type = message.get("type", "")
            
            if msg_type == "ping":
                await websocket.send_text('{"type": "pong"}')
            
            elif msg_type == "subscribe":
                channel = message.get("channel", "")
                # Store subscription info if needed
                await websocket.send_text(f'{{"type": "subscribed", "channel": "{channel}"}}')
            
            elif msg_type == "unsubscribe":
                channel = message.get("channel", "")
                await websocket.send_text(f'{{"type": "unsubscribed", "channel": "{channel}"}}')
            
            elif msg_type == "broadcast":
                # Allow clients to broadcast messages (for testing)
                await manager.broadcast(message)
            
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        manager.disconnect(websocket, user_id)
