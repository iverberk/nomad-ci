package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/manveru/faker"
)

func main() {

	router := mux.NewRouter().StrictSlash(true)
	router.HandleFunc("/", Name)

	log.Fatal(http.ListenAndServe(":8081", router))
}

func Name(w http.ResponseWriter, r *http.Request) {
	fake, err := faker.New("en")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(""))
	}
	fmt.Fprint(w, fake.Name())
}
