package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/signal"

	"github.com/go-pg/pg/v10"
	amqp "github.com/rabbitmq/amqp091-go"
)

const serviceName = "backend"

func main() {
	log.Printf("Starting %s...\n", serviceName)

	ctx, cancelFunc := signal.NotifyContext(context.Background())
	defer cancelFunc()

	postgresConnected := true
	err := connectToPostgres(ctx)
	if err != nil {
		postgresConnected = false
		log.Printf("Failed to connect to database: %v\n", err)
	}

	rabbitmqConnected := true
	err = connectToRabbitmq()
	if err != nil {
		rabbitmqConnected = false
		log.Printf("Failed to connect to rabbitmq: %v\n", err)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		_, _ = fmt.Fprintf(w, "Hello from backend\npostgresConnected: %v\nrabbitmqConnected: %v\n", postgresConnected, rabbitmqConnected)
	})

	_ = http.ListenAndServe(":80", nil)

	<-ctx.Done()
	log.Printf("Stopping %s...\n", serviceName)
}

func connectToPostgres(ctx context.Context) error {
	db := pg.Connect(&pg.Options{
		Addr:     fmt.Sprintf("%s:%s", os.Getenv("POSTGRES_HOST"), os.Getenv("POSTGRES_PORT")),
		User:     os.Getenv("POSTGRES_USER"),
		Password: os.Getenv("POSTGRES_PASSWORD"),
		Database: os.Getenv("POSTGRES_DATABASE"),
	})

	err := db.Ping(ctx)
	if err != nil {
		return err
	}
	defer func() {
		err := db.Close()
		if err != nil {
			log.Printf("Failed to close database connection: %v\n", err)
		}
	}()

	return nil
}

func connectToRabbitmq() error {
	url := fmt.Sprintf("amqp://%s:%s@%s:%s/", url.QueryEscape(os.Getenv("RABBITMQ_USER")), url.QueryEscape(os.Getenv("RABBITMQ_PASSWORD")), os.Getenv("RABBITMQ_HOST"), os.Getenv("RABBITMQ_PORT"))

	conn, err := amqp.Dial(url)
	if err != nil {
		return err
	}
	defer func() {
		err := conn.Close()
		if err != nil {
			log.Printf("Failed to close rabbitmq connection: %v\n", err)
		}
	}()

	return nil
}
