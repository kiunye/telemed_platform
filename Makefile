.PHONY: help setup deps test format lint compile clean db-setup db-migrate db-reset docker-up docker-down

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Initial setup: get deps, setup database
	@echo "Setting up project..."
	cd telemed_core && mix deps.get
	cd telemed_api && mix deps.get
	cd telemed_admin && mix deps.get
	cd telemed_jobs && mix deps.get
	@echo "Setup complete!"

deps: ## Get all dependencies
	@echo "Getting dependencies..."
	cd telemed_core && mix deps.get
	cd telemed_api && mix deps.get
	cd telemed_admin && mix deps.get
	cd telemed_jobs && mix deps.get

test: ## Run all tests
	@echo "Running tests..."
	cd telemed_core && mix test
	cd telemed_api && mix test
	cd telemed_admin && mix test
	cd telemed_jobs && mix test

format: ## Format all code
	@echo "Formatting code..."
	cd telemed_core && mix format
	cd telemed_api && mix format
	cd telemed_admin && mix format
	cd telemed_jobs && mix format

lint: ## Run linter (Credo if available)
	@echo "Linting code..."
	cd telemed_core && mix credo || echo "Credo not available"
	cd telemed_api && mix credo || echo "Credo not available"
	cd telemed_admin && mix credo || echo "Credo not available"

compile: ## Compile all apps
	@echo "Compiling..."
	cd telemed_core && mix compile
	cd telemed_api && mix compile
	cd telemed_admin && mix compile
	cd telemed_jobs && mix compile

clean: ## Clean build artifacts
	@echo "Cleaning..."
	cd telemed_core && mix clean
	cd telemed_api && mix clean
	cd telemed_admin && mix clean
	cd telemed_jobs && mix clean

db-setup: ## Create database
	@echo "Setting up database..."
	cd telemed_core && mix ecto.create

db-migrate: ## Run migrations
	@echo "Running migrations..."
	cd telemed_core && mix ecto.migrate

db-reset: ## Reset database (drop, create, migrate)
	@echo "Resetting database..."
	cd telemed_core && mix ecto.reset

docker-up: ## Start Docker PostgreSQL
	@echo "Starting PostgreSQL..."
	docker-compose up -d

docker-down: ## Stop Docker PostgreSQL
	@echo "Stopping PostgreSQL..."
	docker-compose down

dev: ## Start development servers (requires multiple terminals)
	@echo "To start development:"
	@echo "  Terminal 1: cd telemed_api && mix phx.server"
	@echo "  Terminal 2: cd telemed_admin && mix phx.server"
