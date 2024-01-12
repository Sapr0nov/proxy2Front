MAKEFLAGS += --no-print-directory
SHELL = /bin/bash
UID = $(shell id -u)
N ?= 0
NEW_VALUE ?= 'TEST'

include .env

.DEFAULT: help

help:  ## Показать список команд
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

init: ## Инициализиурем начальные значания 
	@echo "меняем localhost на домен VM"
	@read -p "Введите адрес вашей виртуальной машины (example: familia-vm.galaxy.loc): " vm_name; \
	make save2env param=BASE_HOSTNAME value=$$vm_name
	@read -p "Введите адрес репозитония чьи ветки будем поднимать (example: git@devgit.aa.digital:8020/autoacademy/front-service.git): " ssh_repo; \
	make save2env param=BASE_GIT value=$$ssh_repo

nginx-start: ## Собирает образы докера для nginx и запускает его
	@make nginx-stop
	@make nginx-build
	@make nginx-run

front-load: ## Вытягивает Front из GIT'a. Укажите номер фронта N=1
	@if ! [ -d "../src" ]; then echo "создаем папку для исходников Front" && mkdir -p ../src; fi
	@if ! [ -d "../src/front-service-$(N)" ]; then echo "создаем папку для исходников Front-$(N)" && mkdir -p ../src/front-service-$(N); fi
	@echo "очищаем папку для исходников Front-$(N) (/src/front-service-$(N))"
	@sudo rm -rf ../src/front-service-$(N)
	@echo "вытягиваем в созданную папку проект"
	@read -p "Укажите ветку которую надо вытянуть (example: master): " branch_name; \
	[ -d "../src/front-service-$(N)" ] || git clone -b $$branch_name ssh://$(BASE_GIT) ../src/front-service-$(N)
	@echo "создаем docker-front файл для контейнера"
	@if ! [ -f "docker-front-$(N).yml" ] && [ -f "docker-front.yml" ]; then echo "Копируем файл докера front-service" && cat docker-front.yml |sed -e "s/front-service/front-service-$(N)/g"| sed  -e "s/\"3000\"/\"$(shell expr $N + 3000)\"/g"| sed -e "s/3000:3000/$(shell expr $N + 3000):3000/g" > docker-front-$(N).yml; fi
	@echo "создаем конфигурацию Nginx для front-service-$(N)"
	@if ! [ -f "$(NGINX_CONF)/front-$(N).conf" ] && [ -f "$(NGINX_CONF)/front.conf" ]; then echo "Копируем файл конфигурации nginx" && cat $(NGINX_CONF)/front.conf |sed -e "s/80/$(shell expr $N + 80)/g"| sed  -e "s/3000/$(shell expr $N + 3000)/g" > $(NGINX_CONF)/front-$(N).conf; fi
	make nginx-restart
	@echo "Теперь можно использовать \"make front-start N=$(N)\""

front-start: ## Собираем и запускаем фронт. Укажите номер фронта N=1
	@make stop N=$(N)
	@make build N=$(N)
	@make run N=$(N)

stats: ## Показать поднятые ветки
	@find ../src -type d -name front-service-* -exec make show dir={} \;

clear-conf: ## Удалить все созданные конфигурации
	@sudo rm -rf $(NGINX_CONF)/front-*.conf;
	@sudo rm -rf docker-front-*.yml;

stop-all: ## Остановить все контейнеры
	@find . -name "docker-front-*.yml" -exec docker-compose --log-level ERROR -f {} down --remove-orphans \;
	@docker-compose --log-level ERROR stop

start-all: ## Запустить все контейнеры
	@echo "обновляем файлы .env-cmdrc"
	@find ../src/front-service-* -name ".env-cmdrc" -exec sed -i 's/localhost/$(BASE_HOSTNAME)/g' {} +
	@echo "Запускаем контейнеры"
	@find . -name "docker-front-*.yml" -exec docker-compose --log-level ERROR -f {} up -d \;
	@docker-compose --log-level ERROR up -d nginx

docker-clear: ## Остановить и удалить все образы
	@docker-compose stop
	@docker container prune
	@docker image prune -a
	@docker network prune

save2env: # Внутренняя обработка - сохранения файла env
	@sed -i "s/^$(param)=.*$$/$(param)=$(subst /,\/,$(value))/" .env

show: # Показать ветку для папки
	@echo $(BASE_HOSTNAME):8$(dir)|sed 's/..\/src\/front-service-//'
	@cd $(dir) && git branch
	@echo " "; 

stop: # Останавливаем контейнер front-service. Укажите номер фронта N=1
	@docker-compose -f docker-front-$(N).yml stop front-service-$(N)

build: # Собирает образы докера для front-service. Укажите номер фронта N=1
	@if [ -f "../src/front-service-$(N)/.env-cmdrc" ]; then sed -i "s/localhost/$(BASE_HOSTNAME)/g" ../src/front-service-$(N)/.env-cmdrc; fi
	@docker-compose -f docker-front-$(N).yml build --no-cache front-service-$(N)

run: # Запускаем контейнер front-service. Укажите номер фронта N=1
	@if [ -f "../src/front-service-$(N)/.env-cmdrc" ]; then sed -i "s/localhost/$(BASE_HOSTNAME)/g" ../src/front-service-$(N)/.env-cmdrc; fi
	@docker-compose -f docker-front-$(N).yml up -d front-service-$(N)

nginx-stop: # Останавливаем контейнеры nginx
	@docker-compose stop nginx

nginx-build: # Собирает образы докера для nginx
	@docker-compose build --no-cache nginx
	@echo "Докер образы собраны. Выполните \"make nginx-run\" для их запуска"

nginx-run: # Запускаем контейнеры nginx
	@docker-compose up -d nginx

nginx-restart: # Перезапускаем контейнеры nginx
	@docker-compose stop nginx
	@docker-compose up -d nginx

