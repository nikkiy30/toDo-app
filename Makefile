COMPOSE := docker compose -p github-todo-app

.PHONY: help start stop restart status logs logs-db logs-web db-shell check url pre-push-check install-hooks

help:
	@echo "Local Learning Queue"
	@echo ""
	@echo "Usage:"
	@echo "  make start     Start the local app"
	@echo "  make stop      Stop containers without deleting DB data"
	@echo "  make restart   Restart the local app"
	@echo "  make status    Show container status"
	@echo "  make logs      Follow all logs"
	@echo "  make db-shell  Open psql in todo-db"
	@echo "  make check     Check app and API health"
	@echo "  make url       Print local URLs"
	@echo "  make pre-push-check"
	@echo "                 Check for accidental files before pushing"
	@echo "  make install-hooks"
	@echo "                 Install the local pre-push safety hook"

start:
	$(COMPOSE) up -d --build
	@echo ""
	@echo "App: http://localhost:8000"
	@echo "DB:  localhost:5433"

stop:
	$(COMPOSE) down

restart: stop start

status:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

logs-db:
	$(COMPOSE) logs -f db

logs-web:
	$(COMPOSE) logs -f web

db-shell:
	$(COMPOSE) exec db sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

check:
	@curl -s -o /tmp/local-learning-queue.html -w "home: %{http_code}\n" http://localhost:8000/
	@curl -s -o /tmp/local-learning-queue-todos.json -w "api:  %{http_code}\n" http://localhost:8000/todos

url:
	@echo "App: http://localhost:8000"
	@echo "DB:  localhost:5433"

pre-push-check:
	@scripts/pre-push-check.sh

install-hooks:
	@mkdir -p .git/hooks
	@printf '%s\n' '#!/usr/bin/env sh' 'exec scripts/pre-push-check.sh "$$@"' > .git/hooks/pre-push
	@chmod +x .git/hooks/pre-push scripts/pre-push-check.sh
	@echo "Installed .git/hooks/pre-push"
