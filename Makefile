MAKEFLAGS += --no-print-directory
SHELL = /bin/bash
UID = $(shell id -u)
N ?= 0
NEW_VALUE ?= 'TEST'

include .env

.DEFAULT: help

help:  ## Display command list
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

docker-clear: ## stop and remove all images
	@docker-compose stop
	@docker container prune
	@docker image prune -a
	@docker network prune

save2env:
	@sed -i "s/^$(param)=.*$$/$(param)=$(subst /,\/,$(value))/" .env

init: ## инициализиурем начальные значания 
	@echo "меняем localhost на домен VM"
	@read -p "Введите адрес вашей виртуальной машины (example: familia-vm.galaxy.loc): " vm_name; \
	make save2env param=BASE_HOSTNAME value=$$vm_name
	@read -p "Введите адрес репозитония чьи ветки будем поднимать (example: git@devgit.aa.digital:8020/autoacademy/front-service.git): " ssh_repo; \
	make save2env param=BASE_GIT value=$$ssh_repo

front-load: ## вытягивает Front из GIT'a. Можно указать номер фронта N=1
	@if ! [ -d "../src" ]; then echo "создаем папку для исходников Front" && mkdir -p ../src; fi
	@if ! [ -d "../src/front-service-$(N)" ]; then echo "создаем папку для исходников Front-$(N)" && mkdir -p ../src/front-service-$(N); fi
	@echo "очищаем папку для исходников Front-$(N) (/src/front-service-$(N))";
	@sudo rm -rf ../src/front-service-$(N);
	@echo "вытягиваем в созданную папку проект"
	@read -p "Укажите ветку которую надо вытянуть (example: master): " branch_name; \
	[ -d "../src/front-service-$(N)" ] || git clone -b $$branch_name ssh://$(BASE_GIT) ../src/front-service-$(N);
	@echo "создаем docker-front файл для контейнера"
	@if ! [ -f "docker-front-$(N).yml" ] && [ -f "docker-front.yml" ]; then echo "Копируем файл докера front-service" && cat docker-front.yml |sed -e "s/front-service/front-service-$(N)/g"| sed  -e "s/\"3000\"/\"$(shell expr $N + 3000)\"/g"| sed -e "s/3000:3000/$(shell expr $N + 3000):3000/g" > docker-front-$(N).yml; fi
	@echo "создаем конфигурацию Nginx для front-service-$(N)"
	@if ! [ -f "$(NGINX_CONF)/front-$(N).conf" ] && [ -f "$(NGINX_CONF)/front.conf" ]; then echo "Копируем файл конфигурации nginx" && cat $(NGINX_CONF)/front.conf |sed -e "s/80/$(shell expr $N + 80)/g"| sed  -e "s/3000/$(shell expr $N + 3000)/g" > $(NGINX_CONF)/front-$(N).conf; fi
	@echo "Теперь можно использовать \"make build N=$(N)\""

stop-nginx: ## останавливаем контейнеры nginx
	@docker-compose stop nginx
run-nginx: ## запускаем контейнеры nginx
	@docker-compose up -d nginx

stop-all: ## TODO останавливаем контейнеры nginx front-service и proxy-service
	@docker-compose stop

build-all: ## TODO собирает образы докера для nginx и front-service. Можно указать номер фронта N=1
	@docker-compose stop
	@docker-compose build --no-cache nginx
	@echo "Докер образы собраны. Выполните \"make run\" для их запуска"

run: ## запускаем контейнер front-service. Можно указать номер фронта N=1
	@docker-compose -f docker-front-$(N).yml up -d front-service-$(N)

stop: ## останавливаем контейнеры nginx front-service и proxy-service. Можно указать номер фронта N=1
	@docker-compose -f docker-front-$(N).yml stop front-service-$(N)

build: ## собирает образы докера для nginx и front-service. Можно указать номер фронта N=1
	@if [ -f "../src/front-service-$(N)/.env-cmdrc" ]; then sed -i "s/localhost/$(BASE_HOSTNAME)/g" ../src/front-service-$(N)/.env-cmdrc; fi
	@docker-compose -f docker-front-$(N).yml build --no-cache front-service-$(N)
	@echo "Теперь можно использовать \"make run N=$(N)\""

clear-conf: ## удалить все созданные конфигурации
	@sudo rm -rf $(NGINX_CONF)/front-*.conf;
	@sudo rm -rf docker-front-*.yml;