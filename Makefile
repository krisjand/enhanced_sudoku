export PATH := $(CURDIR)/bin:$(PATH)

.PHONY: run build test docker-run

run:
	cd backend && go run ./api/

build:
	cd backend && go build -o ../bin/server ./api/

test:
	cd backend && go test ./...

docker-run:
	docker compose up --build
