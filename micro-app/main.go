package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/garyburd/redigo/redis"
	"github.com/gorilla/mux"
)

var (
	config Config
	cache  redis.Conn
)

type Config struct {
	// Database settings.
	RedisHost   string `json:"redis_host"`
	RedisPort   int64  `json:"redis_port"`
	NameService string `json:"name_service_url"`
	AgeService  string `json:"age_service_url"`
}

func main() {

	// Read configuration and connect to Redis
	setupConfig()

	var err error
	cache, err = setupRedis()
	if err != nil {
		log.Fatalln("Unable to connect to redis, shutting down.")
	}

	// Make sure we close the Redis connection
	defer cache.Close()

	router := mux.NewRouter().StrictSlash(true)
	router.HandleFunc("/", Introduce)

	log.Println("Application started successfully, listening for connections.")

	http.ListenAndServe(":8080", router)
}

// This function reads the application configuration from a file, allowing
// environment variables to override configuration.
func setupConfig() {
	// Read config from file
	data, err := ioutil.ReadFile("config.json")
	// Fallback to default values.
	switch {
	case os.IsNotExist(err):
		log.Println("Config file missing using defaults")
		config = Config{
			RedisHost:   "172.16.250.130",
			RedisPort:   6379,
			NameService: "127.0.0.1:8081",
			AgeService:  "127.0.0.1:8082",
		}
	case err == nil:
		if err := json.Unmarshal(data, &config); err != nil {
			log.Fatal(err)
		}
	default:
		log.Println(err)
	}

	// Validate config
	if config.RedisHost == "" || config.RedisPort == 0 || config.AgeService == "" || config.NameService == "" {
		log.Fatal("Invalid or missing configuration")
	}
}

func setupRedis() (redis.Conn, error) {
	redisUrl := fmt.Sprintf("%s:%d", config.RedisHost, config.RedisPort)
	log.Println("Connecting to redis at", redisUrl)

	// Establish redis connection
	dialOptions := redis.DialConnectTimeout(2 * time.Second)

	maxAttempts := 20
	var err error
	var c redis.Conn
	for attempts := 1; attempts <= maxAttempts; attempts++ {
		c, err = redis.Dial("tcp", redisUrl, dialOptions)
		if err == nil {
			// Double-check communication
			_, err = c.Do("PING")
			if err == nil {
				return c, nil
			}
		}
		log.Println(err)
		time.Sleep(time.Duration(attempts) * time.Second)
	}

	return nil, err
}

func Introduce(w http.ResponseWriter, r *http.Request) {

	var name, age []byte
	var introduction string

	clear := r.URL.Query().Get("clear")
	if len(clear) != 0 {
		log.Println("clear cache")
		_, err := cache.Do("DEL", "introduction")
		if err != nil {
			log.Println("Could not clear cache!")
		}
	} else {
		// Try to read from cache
		introduction, err := redis.String(cache.Do("GET", "introduction"))
		if err == nil {
			// fast path
			log.Println("cache hit")
			fmt.Fprintln(w, introduction)
			return
		}
		log.Println("cache miss")
	}

	// Try to get a name
	resp, err := http.Get("http://" + config.NameService)
	if err != nil {
		log.Println(err)
	} else {
		defer resp.Body.Close()
		name, err = ioutil.ReadAll(resp.Body)
		if err != nil {
			log.Println(err)
		}
	}

	// Try to get an age
	resp, err = http.Get("http://" + config.AgeService)
	if err != nil {
		log.Println(err)
	} else {
		defer resp.Body.Close()
		age, err = ioutil.ReadAll(resp.Body)
		if err != nil {
			log.Println(err)
		}
	}

	if len(name) == 0 || len(age) == 0 {
		w.WriteHeader(http.StatusServiceUnavailable)
		fmt.Fprintf(w, "Unable to reach services!")
		return
	}

	introduction = fmt.Sprintf("<div id=\"intro\">Hello, my name is %s and I'm %s years old and I live in the %s environment!</div>", string(name), string(age), os.Getenv("ENV"))

	store := r.URL.Query().Get("store")
	if len(store) != 0 {
		log.Println("Storing introduction in cache")
		_, err := cache.Do("SET", "introduction", introduction)
		if err != nil {
			log.Println("Unable store introduction in cache!")
		}
	}

	fmt.Fprintln(w, introduction)
}
