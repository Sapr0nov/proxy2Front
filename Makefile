KNOWN_TARGETS = src
SHELL=/bin/bash
UID=$(shell id -u)
GIT_HOST = git@devgit.src.digital
PREP_COMPOSER = cd /var/www/ && composer install && chown ${UID}:${UID} vendor/ -R
PREP_FRONTEND = yarn global add pm2 env-cmd && yarn install && env-cmd -e developer yarn build-dev
PROJECT_NAME = proxy-service

include .env

.DEFAULT: help


help:  ## Отображаем список команд
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

docker-clear: ## Остановить и удалить все контейнеры
	@docker-compose stop
	@docker container prune
	@docker image prune -a
	@docker network prune

run: ## Запускаем контейнеры nginx и front-service 
	@docker-compose up -d nginx

stop: ## Останавливаем контейнеры nginx front-service и proxy-service
	@docker-compose stop

# не обязательные команды
build: ## собирает образы докера для nginx
	@docker-compose stop
	@docker-compose build --no-cache nginx
	@echo "Докер образы собраны. Выполните \"make run\" для их запуска"
