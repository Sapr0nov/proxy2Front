#Прокси сервер для подключение бэка с другого домена к фронту

# Установка
## Установка docker
Скачивать лучше по инструкции с официального сайта. https://docs.docker.com/engine/install/ubuntu/
```shell
 sudo apt-get update
 sudo apt-get install ca-certificates curl gnupg
```

Создаем ключи GPG докера:
```shell
 sudo install -m 0755 -d /etc/apt/keyrings
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
 sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

Настраиваем репозиторий:
```shell
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
```shell
sudo apt-get update
```
```shell
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
## Установка docker-compose
```shell
sudo apt install docker-compose
```
## Так же потребуется make
```shell
sudo apt install make
```
## Развёртывание проекта

### Скачивание проекта

Подключиться к своей виртуальной машине по ssh
Перейти в домашний каталог
```shell script
cd ~
```
Создать папку проекта
```shell script
mkdir testStand
```
Перейти в созданную папку
```shell script
cd testStand
```
Клонировать репозиторий в папку (при необходимости ввести пароль от ssh ключа)
```shell script
git clone ssh://git@github.com:Sapr0nov/proxy2Front.git && cd test
```

Копируем файл настроек (при необходимости вносим корректировки)
```shell script
cp .env.example .env
```
Настриваем фронт (индивидуально для каждого проекта)

Собираем необходимые образы докера
```shell script
 make build
```

## Работа с проектом
#### В директории test (cd ~/testStand/test)
- поднять контейнеры
```shell
make run
```

## Подмена api ответов
- Папка routes содержит путь по которму происходит подмена /api/v1/name
- name - имя сервиса в котором надо осуществить изменение ответа, образец tmp_region