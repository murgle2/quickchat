package main

import (
	"log"
	"net/http"
	"github.com/gorilla/websocket"
)

// global variables are usualy bad practice..

// map where key is pointer to websocket
var clients = make(map[*websocket.Conn]bool)
// channel that acts as a queue for msgs sent by clients
var broadcast = make(chan Message)

// takes normal http connection and upgrades to websocket
var upgrader = websocket.Upgrader{}

// holds our messages
// backticks are metadata used by go to serialize/unserialize to/from json
type Message struct {
	Email string `json:"email"`
	Username string `json:"username"`
	Message string `json:"message"`
}

func main() {
	// create a simple file server
	fs := http.FileServer(http.Dir("../public"))
	http.Handle("/", fs)
	// configure websocket route
	http.HandleFunc("/ws", handleConnections)
	// start listening for inc messages
	go handleMessages()
	// start server on localhost:8000 and log errors
	log.Println("http server started on 8000")
	err := http.ListenAndServe(":8000", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}

func handleConnections(w http.ResponseWriter, r *http.Request) {
	// upgrade initial get req to websocket
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Fatal(err)
	}
	// make sure connection closed when function returns
	defer ws.Close()
	// register new client
	clients[ws] = true

	for {
		var msg Message
		// read in new message as json and map it to a message obj
		err := ws.ReadJSON(&msg)
		if err != nil {
			log.Printf("error: %v", err)
			delete(clients, ws)
			break
		}
		// send the newly received msg to broadcast channel
		broadcast <- msg
	}
}

func handleMessages() {
	for {
		// grab next msg from broadcast channel
		msg := <-broadcast
		// send it to every client that is connected
		for client := range clients {
			err := client.WriteJSON(msg)
			if err != nil {
				log.Printf("error: %v", err)
				client.Close()
				delete(clients, client)
			}
		}
	}
}