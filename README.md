#Стенд для разработки фронтенда

# Установка
## Установка docker
Скачивать лучше по инструкции с официального сайта (не через snap). https://docs.docker.com/engine/install/ubuntu/
```shell
 sudo apt-get update
 sudo apt-get install ca-certificates curl gnupg
```
Add Docker’s official GPG key:
```shell
 sudo install -m 0755 -d /etc/apt/keyrings
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
 sudo chmod a+r /etc/apt/keyrings/docker.gpg
```
Use the following command to set up the repository:
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
### Создание токена для gitlab
- зайдите в **gitlab**, перейти в **Settings -> Access Tokens** (https://devgit.aa.digital/-/profile/personal_access_tokens)
- введите имя токена, например, **academy**
- выберите следующие **read** скопы: **read_api, read_repository, read_registry**
- создайте токен

**ВАЖНО!** Токен, который будет отображен сверху необходимо сохранить, повторно его уже будет не увидеть

- зарегистрируйте токен в докере
```shell
docker login -u gitlab-ci-token -p {токен} registry.devgit.aa.digital
```

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
Клонировать ветку репозитория в папку (при необходимости ввести пароль от ssh ключа)
```shell script
git clone -b v3.0-multi-front ssh://git@devgit.aa.digital:8020/s.sapronov/test.git && cd test
```

Копируем файл настроек (при необходимости вносим корректировки)
```shell script
cp .env.example .env
```
Команда make init задает переменные BASE_HOSTNAME и BASE_GIT, их можно задать вручную в файле .env
```shell script
make init
```

## Работа с проектом
#### В директории test (cd ~/testStand/test)

Вытягиваем репозиторий Front'a  параметр N=1 указывает на номер собираемого контейнера и порта (80+N), на котором он будет поднят
```shell script
 make front-load N=1
```

Собираем необходимые образы докера
```shell script
 make build N=1
```
И запускаем нужный образ докера (обратите внимание - требуется перезапуск nginx, если Nый конфиг был создан впервые)
```shell script
 make run N=1
 make stop-nginx
 make run-nginx
```

Примечание (запуск Front'a занимает несколько минут, и происходит медленнее чем nginx по-этому какое-то вермя может отображаться 502 ошибка. Просто подождите.)

## Для изменения ответа запроса на сервере

- Копируем в папке routes/api/v1 папку с именем region, и переименовываем её следующим после v1 в оригинальном запросе
- Например для запросов начинающихся с /api/v1/product/ :
```shell
cp -r ~/testStand/test/routes/api/v1/region ~/testStand/test/routes/api/v1/product
```
- Устанавливаем права 755 (временное решение!) на папку
```shell
sudo chmod -R 755 ~/testStand/test/routes/api/v1/product
```
Далее через самбу меняем файл index.php в блоке "Здесь меняем нужные параметры"
где $body['data'] - объект ответа от сервера
соответственно можно проверить наличие нужных полей, изменить, заменить или добавить новое.

```shell
# Здесь меняем нужные параметры
if (isset($body['data']) && isset($body['data']['name'])) {
    $body['data']['name'] = "МОЯ " . $body['data']['name'];
    $body['data']['new_filed'] = "Новое поле";
}
# //Здесь меняем нужные параметры
```