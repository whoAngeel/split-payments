package handler

import (
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

type WSHub struct {
	mu       sync.RWMutex
	sessions map[string][]*websocket.Conn
}

var hub = &WSHub{sessions: make(map[string][]*websocket.Conn)}

func (h *WSHub) Add(sessionID string, conn *websocket.Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.sessions[sessionID] = append(h.sessions[sessionID], conn)
}

func (h *WSHub) Remove(sessionID string, conn *websocket.Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	conns := h.sessions[sessionID]
	for i, c := range conns {
		if c == conn {
			h.sessions[sessionID] = append(conns[:i], conns[i+1:]...)
			break
		}
	}
}

func (h *WSHub) Broadcast(sessionID string, msg []byte) {
	h.mu.Lock()
	defer h.mu.Unlock()
	for _, conn := range h.sessions[sessionID] {
		conn.WriteMessage(websocket.TextMessage, msg)
	}
}
