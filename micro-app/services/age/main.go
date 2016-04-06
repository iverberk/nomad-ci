package main

import (
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"time"

	"github.com/gorilla/mux"
)

func main() {

	router := mux.NewRouter().StrictSlash(true)
	router.HandleFunc("/", Age)

	log.Fatal(http.ListenAndServe(":8082", router))
}

func Age(w http.ResponseWriter, r *http.Request) {
	rand.Seed(time.Now().Unix())
	fmt.Fprintf(w, "%d", rand.Intn(99)+1)
}
