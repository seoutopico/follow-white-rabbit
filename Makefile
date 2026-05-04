.PHONY: help setup init run run-topic status prune publish

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Create config.yaml from example and initialize feeds
	@if [ -f config.yaml ]; then echo "config.yaml already exists. Edit it directly."; exit 1; fi
	cp config.example.yaml config.yaml
	@echo "Created config.yaml — edit it with your topics and feeds, then run: make init"

init: ## Initialize feed XML files from config
	python3 feed.py init

run: ## Run the full research cycle (all topics)
	bash run-research.sh

run-topic: ## Run a single topic (usage: make run-topic TOPIC=ai-research)
	@if [ -z "$(TOPIC)" ]; then echo "Usage: make run-topic TOPIC=<topic_id>"; exit 1; fi
	claude -p "@research $(TOPIC)"

status: ## Show dashboard of all topics and feeds
	python3 feed.py status

prune: ## Prune old entries (usage: make prune KEEP=50)
	python3 feed.py prune --keep $(or $(KEEP),50)

publish: ## Publish feeds to gh-pages and ping WebSub hub
	@BASE_URL=$$(python3 -c "import yaml; print(yaml.safe_load(open('config.yaml')).get('settings',{}).get('base_url',''))"); \
	bash publish.sh "$$BASE_URL"
