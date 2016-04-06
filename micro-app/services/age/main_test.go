package main

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"

	"github.com/gorilla/mux"
)

var (
	server *httptest.Server
)

func init() {
	router := mux.NewRouter()
	router.HandleFunc("/", Age)

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

	age, err := strconv.ParseInt(string(body), 10, 64)
	if err != nil {
		t.Errorf("Could not convert response body to integer value")
	}

	if age < 1 || age > 99 {
		t.Errorf("Age should be between 1 and 100 (inclusive), got: %d", age)
	}
}
