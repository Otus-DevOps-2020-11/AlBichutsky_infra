# AlBichutsky_infra
AlBichutsky Infra repository

## Домашнее задание №3

Предложить вариант решения для подключения из консоли при помощи команды вида 
``` bash
ssh someinternalhost
```
из локальной консоли рабочего устройства, чтобы подключение выполнялось по алиасу `someinternalhost`

### Решение:  
Адреса хостов:
```
bastion_IP = 178.154.253.88
someinternalhost_IP = 10.130.0.19
```

1. Создаем на локальном хосте файл `config` в каталоге `~/.ssh` 
```bash
touch ~/.ssh/config
```
2. Добавляем в него следующую конфигурацию ssh:
```
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
3. Подключаемся к `someinternalhost` по алиасу, используя ProxyJump через `bastion`:
```
ssh someinternalhost
``` 