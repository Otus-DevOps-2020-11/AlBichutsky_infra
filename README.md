# AlBichutsky_infra

AlBichutsky Infra repository

## Домашнее задание №3

Предложить вариант решения для подключения из консоли при помощи команды вида

``` bash
ssh someinternalhost
```

из локальной консоли рабочего устройства, чтобы подключение выполнялось по алиасу `someinternalhost`

### Решение  

Адреса хостов:

```bash
bastion_IP = 178.154.253.88
someinternalhost_IP = 10.130.0.19
```

1.Создаем на локальном хосте файл `config` в каталоге `~/.ssh`

```bash
touch ~/.ssh/config
```

2.Добавляем в него следующую конфигурацию ssh:

```bash
# bastion
Host bastion
   HostName 178.154.253.88
   User appuser
   IdentityFile ~/.ssh/appuser

# someinternalhost
Host someinternalhost
   HostName 10.130.0.19
   User appuser
   IdentityFile ~/.ssh/appuser
   ProxyJump bastion

```

3.Подключаемся к `someinternalhost` по алиасу, используя ProxyJump через `bastion`:

```bash
ssh someinternalhost
```

## Домашнее задание №4

В ДЗ выполняется:

- установка и настройка `yc CLI` для работы с аккаунтом `Yandex Cloud`;
- создание инстанса с помощью CLI;
- установка на хост `ruby`, `mongodb` для работы приложения, деплой тестового приложения;
- создание bash-скриптов для установки на хост необходимых пакетов и деплоя приложения;
- создание startup-сценария `init-cloud` для автоматического деплоя приложения после создания хоста.

Данные для проверки деплоя приложения:

```bash
testapp_IP=130.193.37.97
testapp_port=9292
```

### Основное задание

Команды по настройке системы и деплоя приложения нужно завернуть в bash-скрипты, чтобы не вбивать эти команды вручную:

- cкрипт `install_ruby.sh` должен содержать команды по установке Ruby;
- Скрипт `install_mongodb.sh` должен содержать команды по установке MongoDB;
- Скрипт `deploy.sh` должен содержать команды скачивания кода, установки зависимостей через bundler и запуск приложения.

Приложены скрипты: [install_ruby.sh][1], [install_mongodb.sh][2], [deploy.sh][3].

[1]: install_ruby.sh           "install_ruby.sh"
[2]: install_mongodb.sh        "install_mongodb.sh"
[3]: deploy.sh                 "deploy.sh"

Для создания инстанса используется команда:

```bash
yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --ssh-key ~/.ssh/appuser.pub
```

### Дополнительное задание

В  качестве  доп.  задания  используйте  созданные  ранее  скрипты для создания `startup-script`, который будет запускаться при создании инстанса. В  результате  применения  данной  команды  CLI мы  должны  получать инстанс  с  уже  запущенным  приложением.  Startup-скрипт  необходимо закомитить, а используемую команду CLI добавить в описание репозитория (README.md).

Приложен файл [metadata.yaml](metadata.yaml) (startup-сценарий `init-cloud`), используемый для provision хоста после его создания.  
Для создания инстанса и деплоя приложения используется команда:  

```bash
yc compute instance create \
--name reddit-app \
--hostname reddit-app \
--memory=4 \
--create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
--network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
--metadata serial-port-enable=1 \
--metadata-from-file user-data=./metadata.yaml
```

Подключение к хосту выполняем командой:  

```bash
ssh -i ~/.ssh/appuser yc-user@<ip-адрес хоста>
```
