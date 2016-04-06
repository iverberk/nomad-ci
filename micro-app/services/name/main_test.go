package main

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gorilla/mux"
)

var (
	server *httptest.Server
)

func init() {
	router := mux.NewRouter()
	router.HandleFunc("/", Name)

	server = httptest.NewServer(router)
}

func TestAge(t *testing.T) {

	request, err := http.NewRequest("GET", server.URL, nil)
	res, err := http.DefaultClient.Do(request)

	if err != nil {
		t.Error(err)
	}

	if res.StatusCode != 200 {
		t.Errorf("Success expected, got: %d", res.StatusCode)
	}

	defer res.Body.Close()
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		t.Errorf("Could not response body")
	}

	if len(body) == 0 {
		t.Errorf("Got an empty response")
	}
}
