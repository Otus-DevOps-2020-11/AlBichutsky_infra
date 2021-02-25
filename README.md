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

## Домашнее задание №5  

В ДЗ выполняется:

- Создание базового образа ВМ при помощи Packer в Yandex Cloud (в образ включены mongodb, ruby - установлены через bash-скрипты с помощью shell-provisioner packer).
- Деплой тестового приложения при помощи ранее подготовленного образа.  
- Параметризация шаблона Packer (с использованием var-файла и переменных в самом шаблоне).  
- Создание скрипта `create-reddit-vm.sh` в директории `config-scripts`, который создает ВМ из созданного базового образа с помощью Yandex Cloud CLI (по желанию).

### Основное задание

Приложены файлы:

- шаблон Packer [ubuntu16.json](packer/ubuntu16.json):

```json
{
     "variables": {
            "zone": "ru-central1-a",
            "instance_cores": "4"
        },
     "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{user `service_account_key_file`}}",
            "folder_id": "{{user `folder_id`}}",
            "source_image_family": "{{user `source_image_family`}}",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1",
            "zone": "{{user `zone`}}",
            "instance_cores": "{{user `instance_cores`}}",
            "use_ipv4_nat" : "true"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

В рамках задания в данный шаблон добавлены дополнительные опции билдера (их значения указаны в секции `variables` шаблона):

```json
    ...
     "builders": [
        { 
            "zone": "{{user `zone`}}",
            "instance_cores": "{{user `instance_cores`}}",
        }
    ],
    ...
```

- Пример var-файла с переменными [variables.json.examples](packer/variables.json.examples), который может использоваться вместе с шаблоном Packer. В нем могут храниться секреты (не должен отслеживаться в git). Реальный файл на локальной машине `variables.json` добавлен в .gitignore.

```json
{
  "service_account_key_file": "/opt/keys/yc/key.json",
  "folder_id": "d1ghee2bb8frm0d32dfdf",
  "source_image_family": "ubuntu-1604-lts"
}
```

Команда для валидации шаблона с указанием var-файла (запускаем из каталога `./packer`):

```bash
packer validate -var-file=variables.json ubuntu16.json 
```

Команда для билда образа с указанием var-файла (запускаем из каталога `./packer`):

```bash
packer build -var-file=variables.json ubuntu16.json
```

После сборки образа создаем ВМ, выбрав его (в качестве пользовательсвого образа) в Yandex Cloud.  
Затем подключаемся к ВМ и деплоим приложение командами:

```bash
cd /home
sudo apt-get update
sudo apt-get install -y git
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
```

Проверку запуска приложения можно выполнить, перейдя по адресу: http://<публичный IP ВМ>:9292

### Дополнительное задание

Приложен скрипт [create-reddit-vm.sh](/config-scripts/create-reddit-vm.sh), который запускается на локальной машине и создает ВМ в Yandex Cloud из базового образа, хранящегося в облаке (собранного ранее в Packer):

```bash
#!/bin/bash

instance_name="redditapp-$(date +%d%m%Y-%H%M%S)"

# находим id образа, созданного в packer (по имени)
image_id=$(yc compute image list | grep "reddit-base-1609948540" | awk '{print $2}')

# создаем инстанс
yc compute instance create \
  --name $instance_name \
  --hostname $instance_name \
  --memory=2 \
  --zone ru-central1-a \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --create-boot-disk name=$instance_name,size=10GB,image-id=$image_id \
  --ssh-key ~/.ssh/appuser.pub

```

После создания ВМ, подключаемся к инстансу через ssh:

```bash
ssh -i ~/.ssh/appuser yc-user@<публичный IP-адрес>
```

## Домашнее задание №6

В ДЗ выполняется описание и создание инфраструктуры с помощью `Terraform` в Yandex Cloud:

- Создается инстанс из пользовательского образа, собранного ранее в Packer (с ruby, mongodb).  
- Деплоится тестовое приложение через провижионер Terraform (выполняется bash-скрипт).  
- Описаны входные переменные в файле `variables.tf` (здесь же можно указать и их дефолтные значения), сами переменные определены в файле `terraform.tfvars` и перекрывают дефолтные значения.  
- Добавлена input-переменная `private_key_path` для приватного ключа, используемого провижионерами и input-переменная `zone` для задания зоны в ресурсе `"yandex_compute_instance" "app"` (используется дефолтное значение).
- Отформатированы все конфигурационные файлы с помощью команды `terraform fmt`.
- `terraform.tfvars` добавлен в `.gitignore`, для образца добавлен файл `terraform.tfvars.example`

Для провижинга и подключения к ВМ по ssh требуется сгенерировать приватный и публичный ключ:

```bash
ssh-keygen -t rsa -f ~/.ssh/yc -C yc -P ""
```

Подключаемся к хосту и проверяем состояние сервиса:

```bash
ssh -i ~/.ssh/yc ubuntu@<публичный IP-адрес ВМ>
systemctl status | stop | start puma
```

Приложение должно быть доступно по адресу: http://<публичный IP-адрес ВМ>:9292  

## Домашнее задание №7

В ДЗ выполняется: 
- Cоздание сетевых ресурсов - `yandex_vpc_network`, `yandex_vpc_subnet` и инстанса - `yandex_compute_instance`, определенных в файле `main.tf`. Для того, чтобы сетевые ресурсы с IP-адресами создались до инстанса, используется неявная зависимость:

```
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

# Создание сетевых ресурсов

resource "yandex_vpc_network" "app-network" {
  name = "reddit-app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddit-app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Создание инстанса

resource "yandex_compute_instance" "app" {
  name = "reddit-app"
  zone = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашем задании
      image_id = var.image_id
    }
  }

  network_interface {
    # ссылаемся на сетевой ресурс, описанный выше, чтобы инстанс был создан после подсети и IP
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}

```
- В каталоге `packer` созданы 2 новых шаблона:   
`db.json` для сборки образа `reddit-db-base` (содержит mongodb).   
`app.json` для сборки образа `reddit-app-base` (содержит ruby).    

Выполнена сборка образов `packer` в YC на базе `ubuntu 16.04`.

Конфигурация ресурсов `terraform` была разделена на несколько файлов:
`main.tf`

```
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}
```
`app.tf` - создается инстанс из образа `reddit-app-base`

```
resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  labels = {
    tags = "reddit-app"
  }
  resources {
    cores  = 1
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```
`db.tf`  - создается инстанс из образа `reddit-db-base`

```
resource "yandex_compute_instance" "db" {
  name = "reddit-db"
  labels = {
    tags = "reddit-db"
  }

  resources {
    cores  = 1
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```

`vpc.tf` - создается сетевой ресурс.
```
resource "yandex_vpc_network" "app-network" {
  name = "app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```
В `outputs.tf` добавлены nat адреса инстансов

```
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
output "external_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.nat_ip_address
}
```

После запуска инфраструктуры в следующем задании `db.tf`, `app.tf`, `vpc.tf` были удалены.

- созданы модули в каталоге `modules` (их конфиги лежат в каталогах `app`, `db`)

- Файл `main.tf`, в котором вызываются модули, а также переменные лежат в каталогах для разных окружений - `stage` и `prod`

Для загрузки модулей необходимо перейти в `stage` и `prod` и выполнить комманду:

```bash 
# инциализация terraform в новом каталоге
terraform init
# загрузка модулей (если были изменения)
terraform get
```
Модули загружаются в каталог `.terraform`

`main.tf`:

```
provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

# Создаем VPC-ресурсы для ВМ: сеть "app-network" и подсеть "app-subnet"

# resource "yandex_vpc_network" "app-network" {
# name = "app-network"
# }

# resource "yandex_vpc_subnet" "app-subnet" {
#  name           = "app-subnet"
#  zone           = "ru-central1-a"
#  network_id     = "${yandex_vpc_network.app-network.id}"
#  v4_cidr_blocks = ["192.168.10.0/24"]
# }

module "app" {
  source          = "../modules/app"
  public_key_path = var.public_key_path
  app_disk_image  = var.app_disk_image
  # сейчас подсеть уже создана в YC и определена в terraform.tfvars
  subnet_id       = var.subnet_id
  # если ВМ создается в подсети "app-subnet" после запуска terraform, то
  # - закомментируем параметр выше
  # - закомментируем параметр subnet_id в terraform.tfvars 
  # - расскоментируем ниже
  # subnet_id       = yandex_vpc_subnet.app-subnet.id
}

module "db" {
  source          = "../modules/db"
  public_key_path = var.public_key_path
  db_disk_image   = var.db_disk_image
    # сейчас подсеть уже создана в YC и определена в terraform.tfvars
  subnet_id       = var.subnet_id
  # если ВМ создается в подсети "app-subnet" после запуска terraform, то
  # - закомментируем параметр выше
  # - закомментируем параметр subnet_id в terraform.tfvars 
  # - расскоментируем ниже
  # subnet_id       = yandex_vpc_subnet.app-subnet.id
}

```
- параметризирована конфигурация модулей с помощью `count` и `for_each` для задания имени инстансов и добавлен параметр `core_fraction`.

- конфигурационный файлы отредактированы коммандой  

```bash
terraform fmt
```

### Проверка

Для проверки переходим в каталог `stage` или `prod` и выполняем команду:

```bash
terraform plan
terraform apply
```
Затем подключаемся к созданным инстансам:

```bash
ssh -i ~/.ssh/appuser ubuntu@<публичный ip-адрес>
```

## Домашнее задание №8

### Основное задание

- Установил `ansible` на локальной машине.  
- Запустил инфраструктуру `terraform` из окружения `stage`, описанную в прошлом ДЗ:  

```bash
cd terraform/stage
terraform plan
terraform apply
```

- Создал конфигурационный файл `ansible.cfg` с необходимыми параметрами:

```
[defaults]
; в опции inventory указываем наши файлы статического и динамического инвентори (здесь же можем указать inventory.yml)
inventory = inventory, dynamic_inv.sh
remote_user = ubuntu
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
```

- Создал файлы статического инвентори: 

`inventory` - в INI-формате  

```
[app] # название группы
appserver ansible_host=178.154.230.247 # хост

[db] # название группы
dbserver ansible_host=178.154.231.113 # хост
```

`inventory.yml` - в YAML-формате

```
app:
  hosts:
    appserver:
      ansible_host: 178.154.230.247

db:
  hosts:
    dbserver:
      ansible_host: 178.154.231.113
```

- Проверил доступность удаленных хостов и групп коммандой `ping`:

```bash
# указанных в файле inventory
ansible appserver -i ./inventory -m ping
ansible dbserver -i ./inventory -m ping
ansible app -i ./inventory -m ping
ansible db -i ./inventory -m ping

# указанных в файле inventory.yml
ansible appserver -i ./inventory.yml -m ping
ansible dbserver -i ./inventory.yml -m ping
ansible app -i ./inventory.yml -m ping
ansible db -i ./inventory.yml -m ping

# без указания файлов инвентори - в ansible.cfg инвентори задан и параметры подключения переопределены
ansible all -m ping
ansible appserver -m ping
ansible dbserver -m ping
ansible app -m ping
ansible db -m ping
```

- Выполнил команды на удаленных хостах:

```bash
ansible dbserver -m command -a uptime
# проверка версий приложений
ansible app -m command -a 'ruby -v'
ansible app -m shell -a 'ruby -v; bundler -v'
# проверка статуса сервиса 
ansible db -m command -a 'systemctl status mongod'
ansible db -m systemd -a name=mongod # используется модуль systemd
ansible db -m service -a name=mongod # используется модуль service - более универсален и работает на более старых ОС
# клонирование git-репозиторий (должен быть установлен git)
ansible app -become=yes -m apt -a "name=git state=present"
ansible app -become=yes -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/appuser/reddit'
ansible app -m command -a 'git clone https://github.com/express42/reddit.git /home/appuser/reddit' # должна появиться ошибка при выполнении
```

- Создал и выполнил playbook:

```yml
---
- name: Clone
  hosts: app
  become: yes
  tasks:
    - name: Install git
      apt: 
        name: git
        state: present
    - name: Clone repo
      git:
        repo: https://github.com/express42/reddit.git
        dest: /home/appuser/reddit
```

Команда для запуска сценария `playbook`:

```bash
ansible-playbook clone.yml
```

После повторного выполнения `playbook` проверяем результат:

```
PLAY RECAP ******************************************************************************************************************************
appserver                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

`changed=0`  
Изменений нет, т.к `ansible` поддерживает идемпотентность при выполнении сценариев с использованием модулей. 
Поскольку ожидаемый результат уже был достигнут на удаленном хосте (репозиторий склонирован), сценарий повторно не выполнился.  

Удалим каталог `~/appuser` и повторно запустим `playbook`. `Ansible` проверит, что репозиторий отсутствует и выполнит его клонирование.  
теперь изменения будут отображены при выводе: `changed=1`

```
PLAY RECAP ******************************************************************************************************************************
appserver                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Задание со *

Приложен bash-скрипт `dynamic_inv.sh` - во время выполнения формирует динамически список хостов для Ansible (динамический инвентори). IP-адреса определяются в соответствии с названиями инстансов в YaCloud, созданными ранее через `terraform`: reddit-app-0, reddit-db-dev1.

```bash
#! /bin/bash

# находим публичные IP-адреса хостов по имени инстансов в YC 
appserver=$(yc compute instance list | grep "reddit-app-0" | awk '{print $10}')
dbserver=$(yc compute instance list | grep "reddit-db-dev1" | awk '{print $10}')

if [ "$1" == "--list" ]; then

cat<< EOF
{
  "app": {
    "hosts": [
      "$appserver"
   ],
   "vars": {
      "example_var": "value"
   }
  },
  "db": {
    "hosts": [
      "$dbserver" 
   ],
   "vars": {
      "example_var": "value"
   }
  },
  "_meta": {
    "hostvars": {}
    }
}
EOF
elif [ "$1" == "--host" ]; then
  echo '{"_meta": {hostvars": {}}}'
else
  echo "{ }"
fi
```

**Опции скрипта** 

`--list` - Возвращает список групп, хостов, а также переменных в формате JSON.

`--host` - Поддержка этой опции необязательна и не используется (указана пустая секция `_meta`). Cкрипт возвращает элемент верхнего уровня с именем `_meta`, в котором могут быть перечислены все переменные для хостов.

Пример использования скрипта:

```bash
[root@localhost ansible]# ./dynamic_inv.sh --list
{
  "app": {
    "hosts": [
      "178.154.230.247"
   ],
   "vars": {
      "example_var": "value"
   }
  },
  "db": {
    "hosts": [
      "178.154.231.113"
   ],
   "vars": {
      "example_var": "value"
   }
  },
  "_meta": {
    "hostvars": {}
    }
}
```
Файл динамического инвентори `inventory.json` приложил к ДЗ (формально он не используется, используется скрипт).  
Его создание выполнил командой: 

```bash
./dynamic_inv.sh --list > inventory.json
```

При запуске Ansible скрипт динамического инвентори вызывается с помощью ключей `-i` или `--inventory`

```bash
[root@localhost ansible]# ansible db -m ping -i ./dynamic_inv.sh
178.154.231.113 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
```

Скрипт добавил в `ansible.cfg`, чтобы постоянно не ссылаться на него при запуске Ansible.

```INI
[defaults]
inventory = inventory, dynamic_inv.sh
```

После этого проверил доступность всех хостов, указанных в статическом и динамическом инвентори командой `ansible all -m ping`

```bash
[root@localhost ansible]# ansible all -m ping
178.154.230.247 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
appserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
dbserver | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
178.154.231.113 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

**Отличия схем JSON для динамического и статического инвентори**

Пример статического инвентори в JSON приведен здесь: https://linuxhint.com/ansible_inventory_json_format/
Имеются отличия в синтаксисе файлов, например в JSON динамического инвентори хосты перечисляются в квадратных скобках. 
Кроме того, в динамическом инвентори используется секция `_meta`, которой нет в статическом инвентори.

## Домашнее задание №9

В задании выполняется деплой тестового приложения `reddit` с помощью `ansible-playbook` на инстансах, созданных через `terraform` в YaCloud.  
Вместо пользователя `appuser` указан `ubuntu` (т.к. в прошлых ДЗ публичный ключ пробрасывался для `ubuntu`, он и присутствует в системе).  
На инстансе `appserver` репозиторий приложения клонируется в каталог пользователя `ubuntu`: `/home/ubuntu`.


### Основное задание
  
- Запустил инфраструктуру `terraform` из окружения `stage`, описанную в ДЗ №6:  

```bash
cd terraform/stage
terraform plan
terraform apply
```

- Создал playbook `reddit_app_one_play.yml` с одним сценарием.  
Здесь `db_host` - внутренний IP-адрес сервера mongodb.

```yml
--- 
- name: Configure hosts & deploy application
  hosts: all
  vars:
    mongo_bind_ip: 0.0.0.0  # <-- Переменная задается в блоке vars
    db_host: 10.130.0.27
  tasks:
    - name: Change mongo config file
      become: true  # <-- Выполнить задание от root
      template:
        src: templates/mongod.conf.j2 # <-- Путь до локального файла-шаблона
        dest: /etc/mongod.conf  # <-- Путь на удаленном хосте
        mode: 0644  # <-- Права на файл, которые нужно установить
      tags: db-tag  # <-- Список тэгов для задачи
      notify: restart mongod

    - name: Add unit file for Puma
      become: true
      copy: 
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      tags: app-tag
      notify: reload puma

    - name: Add config for DB connection
      become: true
      template: 
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
      tags: app-tag  

    - name: enable puma
      become: true
      systemd: name=puma enabled=yes
      tags: app-tag

    - name: Install git
      become: true
      apt: 
        name: git
        state: present
      tags: deploy-tag

    - name: Fetch the latest version of application code
      become: true
      git: 
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/ubuntu/reddit
        version: monolith # <-- Указываем нужную ветку
      tags: deploy-tag
      notify: reload puma

    - name: Bundle install
      bundler: 
        state: present
        chdir: /home/ubuntu/reddit # <-- В какой директории выполнить команду bundle
      tags: deploy-tag

  handlers: # <-- Добавим блок handlers и задачу
    - name: restart mongod
      become: true
      service: name=mongod state=restarted

    - name: reload puma
      become: true
      systemd: name=puma state=restarted
```

- Создал шаблоны конфигов в каталоге `templates`: 

`mongod.conf.j2`  
Это конфиг `mongodb`, копируется на инстанс `dbserver`.

```
# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  # default - один из фильтров Jinja2, он задает значение по умолчанию, 
  # если переменная слева не определена
  port: {{ mongo_port | default('27017') }}
  bindIp: {{ mongo_bind_ip }} # <-- Подстановка значения переменной
```

`db_config.j2`  
В конфиг подставляется внутренний IP-адрес сервера `mongodb`, чтобы `reddit` мог подключиться к БД. Копируется на инстанс `appserver`.

```
DATABASE_URL={{ db_host }}
```

- Создал в каталоге `files` файл юнита `puma.service`.  
  Копируется на инстанс `appserver` в профиль пользователя `ubuntu` (куда деплоится приложение).

```INI
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
# EnvironmentFile=/home/appuser/db_config
# User=appuser
# WorkingDirectory=/home/appuser/reddit
EnvironmentFile=/home/ubuntu/db_config
User=ubuntu
WorkingDirectory=/home/ubuntu/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always

[Install]
WantedBy=multi-user.target
```

- Проверил и выполнил сценарии playbook коммандами:

```bash
# проверка
ansible-playbook reddit_app.yml --check --limit db --tags db-tag
ansible-playbook reddit_app.yml --check --limit app --tags app-tag
ansible-playbook reddit_app.yml --check --limit app --tags deploy-tag
# выполнение
ansible-playbook reddit_app.yml --limit db --tags db-tag
ansible-playbook reddit_app.yml --limit app --tags app-tag
ansible-playbook reddit_app.yml --limit app --tags deploy-tag
```

Проверка деплоя приложения:   
http://<публичный IP appserver>:9292

- Затем пересоздал инфраструктуру `terraform`:
  
```bash
terraform destroy
terraform apply -auto-approve=false
```

- На основе `reddit_app_one_play.yml` создал playbook `reddit_app_multiple_plays.yml` с разбивкой на несколько сценариев. Названия тэгов и секция `become: true` указаны здесь для каждого сценария.

```yml
--- 
- name: Configure MongoDB
  hosts: db
  tags: db-tag
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
    - name: restart mongod
      service: name=mongod state=restarted

- name: Configure App
  hosts: app
  tags: app-tag
  become: true
  vars:
    db_host: 10.130.0.3
  tasks:
    - name: Add unit file for Puma
      copy: 
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template: 
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
        owner: ubuntu
        group: ubuntu

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
    - name: reload puma
      systemd: name=puma state=restarted

- name: Deploy App
  hosts: app
  tags: deploy-tag
  become: true
  tasks:  
    - name: Install git
      apt: 
        name: git
        state: present

    - name: Fetch the latest version of application code
      git: 
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/ubuntu/reddit
        version: monolith
      notify: reload puma

    - name: Bundle install
      bundler: 
        state: present
        chdir: /home/ubuntu/reddit

  handlers:
    - name: reload puma
      systemd: name=puma state=restarted
  ```

- Проверил и выполнил сценарии playbook коммандами:

```bash
# проверка (группы хостов не указываем)
ansible-playbook reddit_app.yml --check --tags db-tag
ansible-playbook reddit_app.yml --check --tags app-tag
ansible-playbook reddit_app.yml --check --tags deploy-tag
# выполнение (группы хостов не указываем)
ansible-playbook reddit_app.yml --tags db-tag
ansible-playbook reddit_app.yml --tags app-tag
ansible-playbook reddit_app.yml --tags deploy-tag
```

Проверка деплоя приложения:  
http://<публичный IP appserver>:9292

- Затем пересоздал инфраструктуру `terraform`:
  
```bash
terraform destroy
terraform apply -auto-approve=false
```

- Далее вынес сценарии из `reddit_app_multiple_plays.yml` в отдельные плейбуки, из которых удалена секция `tags`:

`db.yml`

```yaml
- name: Configure MongoDB
  hosts: db
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
    - name: restart mongod
      service: name=mongod state=restarted
```

`app.yml`

```yaml
- name: Configure App
  hosts: app
  become: true
  vars:
    db_host: 10.130.0.11
  tasks:
    - name: Add unit file for Puma
      copy: 
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template: 
        src: templates/db_config.j2
        dest: /home/ubuntu/db_config
        owner: ubuntu
        group: ubuntu

    - name: enable puma
      systemd: name=puma enabled=yes

  handlers:
    - name: reload puma
      systemd: name=puma state=restarted
```

`deploy.yml`

```yaml
- name: Deploy App
  hosts: app
  become: true
  tasks:  
    - name: Install git
      apt: 
        name: git
        state: present

    - name: Fetch the latest version of application code
      git: 
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/ubuntu/reddit
        version: monolith
      notify: reload puma

    - name: Bundle install
      bundler: 
        state: present
        chdir: /home/ubuntu/reddit

  handlers:
    - name: reload puma
      systemd: name=puma state=restarted
```

- Создал файл основного playbook `site.yml`, в котором описывается управление всей конфигурацией инфраструктуры `site.yml`:

```yml
--- 
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
```

- Проверил и запустил основной playbook:

```bash
ansible-playbook site.yml --check 
ansible-playbook site.yml
```

Проверка деплоя приложения:  
http://<публичный IP appserver>:9292

## Домашнее задание №10

### Основное задание

Примечание:   
На инстансе `appserver` репозиторий с приложением `reddit` клонируется в каталог пользователя `ubuntu`: `/home/ubuntu` (а не `appuser`, т.к. в прошлых ДЗ публичный ключ пробрасывался для `ubuntu`)

- Cоздал ansible-роли `app`, `db` для тестового приложения `reddit`.  

```bash
cd ansible
mkdir roles
cd roles
ansible-galaxy init app
ansible-galaxy init db
```

- Плейбуки  `app.yml`, `db.yml` вместе с шаблонами и файлами из ДЗ №9 перенес в роли. 

- Установил коммюнити роль `nginx`:

```bash
cd ansible/roles
ansible-galaxy install -r environments/stage/requirements.yml
```

Теперь актуальные плейбуки имеют вид: 

ansible/playbooks/app.yml

```yml
- name: Configure App
  hosts: app
  become: true
  roles:
    - app
    - jdauphant.nginx
```

ansible/playbooks/db.yml

```yml
- name: Configure MongoDB
  hosts: db
  become: true
  roles: 
    - db
```

- В каталоге `environments` создал папки окружений `stage` и `prod`.   
Указал в них инвентори и создал необходимые папки и файлы (в `group-vars` храним переменные).  
Структура каталога:

```
├── prod
│   ├── credentials.yml
│   ├── group_vars
│   │   ├── all
│   │   ├── app
│   │   └── db
│   ├── inventory
│   └── requirements.yml
└── stage
    ├── credentials.yml
    ├── group_vars
    │   ├── all
    │   ├── app
    │   └── db
    ├── inventory
    └── requirements.yml

```

- Создал новый плейбук `ansible/playbooks/users.yml` для создания пользователя `admin` на всех серверах.

- Зашифровал ключом `ansible-vault` файлы `credentials.yml`, в которых содержатся пароли пользователей: 

```bash
# создать файл ключа с паролем для шифрования
echo "somepass" > vault.key
# шифруем ключом файлы
ansible-vault encrypt environments/stage/credentials.yml # для stage-окружения
ansible-vault encrypt environments/prod/credentials.yml  # для prod-окружения
# расшифровать
ansible-vault encrypt environments/stage/credentials.yml
ansible-vault encrypt environments/prod/credentials.yml
```

Путь к файлу ключа указал в `ansible.cfg` (вместе с другими параметрами)

```INI
[defaults]
; в опции inventory указываем наши файлы статического и динамического инвентори -
; здесь же можем указать inventory.yml и dynamic_inv.sh
inventory = ./environments/stage/inventory
remote_user = ubuntu
private_key_file = ~/.ssh/appuser
# Отключим проверку SSH Host-keys (поскольку они всегда разные для новых инстансов)
host_key_checking = False
# Отключим создание *.retry-файлов (они нечасто нужны, но мешаются под руками)
retry_files_enabled = False
# Явно укажем расположение ролей (можно задать несколько путей через ; )
roles_path = ./roles
# указываем путь к файлу vault.key с паролем для шифрования им конф.файлов
vault_password_file = vault.key

[diff]
# Включим обязательный вывод diff при наличии изменений и вывод 5 строк контекста 
always = True
context = 5
```
- Главный плейбук для запуска теперь имеет вид:

```yml
--- 
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
- import_playbook: users.yml
```

- Старые файлы перенесены в каталог ansible/old, плейбуки в ansible/playbooks

- Структура каталогов ansible в итоге выглядит следующим образом:

```bash
[root@localhost ansible]# tree
.
├── ansible.cfg
├── environments
│   ├── prod
│   │   ├── credentials.yml
│   │   ├── group_vars
│   │   │   ├── all
│   │   │   ├── app
│   │   │   └── db
│   │   ├── inventory
│   │   └── requirements.yml
│   └── stage
│       ├── credentials.yml
│       ├── group_vars
│       │   ├── all
│       │   ├── app
│       │   └── db
│       ├── inventory
│       └── requirements.yml
├── old
│   ├── dynamic_inv.sh
│   ├── files
│   │   └── puma.service
│   ├── inventory.json
│   ├── inventory.yml
│   └── templates
│       ├── db_config.j2
│       └── mongod.conf.j2
├── playbooks
│   ├── app.yml
│   ├── clone.yml
│   ├── db.yml
│   ├── deploy.yml
│   ├── reddit_app_multiple_plays.yml
│   ├── reddit_app_one_play.yml
│   ├── site.yml
│   └── users.yml
├── requirements.txt
├── roles
│   ├── app
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── files
│   │   │   └── puma.service
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── README.md
│   │   ├── tasks
│   │   │   └── main.yml
│   │   ├── templates
│   │   │   └── db_config.j2
│   │   ├── tests
│   │   │   ├── inventory
│   │   │   └── test.yml
│   │   └── vars
│   │       └── main.yml
│   ├── db
│   │   ├── defaults
│   │   │   └── main.yml
│   │   ├── files
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── meta
│   │   │   └── main.yml
│   │   ├── README.md
│   │   ├── tasks
│   │   │   └── main.yml
│   │   ├── templates
│   │   │   └── mongod.conf.j2
│   │   ├── tests
│   │   │   ├── inventory
│   │   │   └── test.yml
│   │   └── vars
│   │       └── main.yml
│   └── jdauphant.nginx
│       ├── ansible.cfg
│       ├── defaults
│       │   └── main.yml
│       ├── handlers
│       │   └── main.yml
│       ├── meta
│       │   └── main.yml
│       ├── README.md
│       ├── tasks
│       │   ├── amplify.yml
│       │   ├── cloudflare_configuration.yml
│       │   ├── configuration.yml
│       │   ├── ensure-dirs.yml
│       │   ├── installation.packages.yml
│       │   ├── main.yml
│       │   ├── nginx-official-repo.yml
│       │   ├── remove-defaults.yml
│       │   ├── remove-extras.yml
│       │   ├── remove-unwanted.yml
│       │   └── selinux.yml
│       ├── templates
│       │   ├── auth_basic.j2
│       │   ├── config_cloudflare.conf.j2
│       │   ├── config.conf.j2
│       │   ├── config_stream.conf.j2
│       │   ├── module.conf.j2
│       │   ├── nginx.conf.j2
│       │   ├── nginx.repo.j2
│       │   └── site.conf.j2
│       ├── test
│       │   ├── custom_bar.conf.j2
│       │   ├── example-vars.yml
│       │   └── test.yml
│       ├── Vagrantfile
│       └── vars
│           ├── Debian.yml
│           ├── empty.yml
│           ├── FreeBSD.yml
│           ├── main.yml
│           ├── RedHat.yml
│           └── Solaris.yml
└── vault.key

```
### Запуск проекта

После деплоя приложение должно быть доступно по адресам:
- http://<публичный IP appserver>:9292 (основной порт приложения) 
- http://<публичный IP appserver>:80 (http-проксирование с nginx port 80 -> port 9292)
- на всех серверах должен быть создан пользователь `admin` с паролем из своего окружения.

Проверяем в `stage` окружении:

```bash
# Создаем инфраструктуру
cd terraform/stage
terraform destroy
terraform apply
# запускаем главный плейбук
cd ansible
ansible-playbook playbooks/site.yml --check  # инвентори stage-окружения указан по умолчанию в ansible.cfg
ansible-playbook playbooks/site.yml
```

Проверяем создание пользователя:

```bash
ssh -i ~/.ssh/appuser ubuntu@<публичный IP>
su - admin
# вводим пароль из зашифрованного конфига окружения environments/stage/credentials.yml
```

Проверяем в `prod` окружениии:

```bash
# Создаем инфраструктуру
cd terraform/prod
terraform destroy
terraform apply
# запускаем главный плейбук
cd ansible
ansible-playbook -i environments/prod/inventory playbooks/site.yml --check
ansible-playbook -i environments/prod/inventory playbooks/site.yml
```

Проверяем создание пользователя:

```bash
ssh -i ~/.ssh/appuser ubuntu@<публичный IP>
su - admin
# вводим пароль из зашифрованного конфига окружения environments/prod/credentials.yml
``` 

## Домашнее задание №11

### Основное задание

- Доработал ansible-роли `app`, `db` для провижинга ВМ в `Vagrant`.

- Описал локальную инфраструктуру в `Vagrantfile`.  
  Роли вызываются через главный плейбук `site.yml`.

```ruby
Vagrant.configure("2") do |config|

  config.vm.provider :virtualbox do |v|
    v.memory = 512
  end

  config.vm.define "dbserver" do |db|
    db.vm.box = "ubuntu/xenial64"
    db.vm.hostname = "dbserver"
    db.vm.network :private_network, ip: "10.10.10.10"

    db.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "db" => ["dbserver"],
      "db:vars" => {"mongo_bind_ip" => "0.0.0.0"}
      }
    end
  end
  
  config.vm.define "appserver" do |app|
    app.vm.box = "ubuntu/xenial64"
    app.vm.hostname = "appserver"
    app.vm.network :private_network, ip: "10.10.10.20"

    app.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/site.yml"
      ansible.groups = {
      "app" => ["appserver"],
      "app:vars" => { "db_host" => "10.10.10.10"}
      }
      ansible.extra_vars = {
      "deploy_user" => "ubuntu"
      }
    end
  end

end
```

- Проверил запуск ролей в Vagrant:

```bash
# Удалить окружение
vagrant destroy -f
# Создать окружение
vagrant up { dbserver | appserver }
# Проверить ВМ
vagrant status
# Проверить наличия боксов Vagrant
vagrant box list
# Выполнить провижинг
vagrant provision { dbserver | appserver }
```

Приложение должно быть доступным по адресу: http://10.10.10.20:9292  

- Установил через `pip` необходимые компоненты для тестирования ansible-ролей с помощью Vagrant: `Molecule`, `Ansible`, `Testinfra` (версии для python 3.6).   

Зависимости указаны в файле `requirements.txt`.

```
ansible>=2.4
molecule>=2.6
# testinfra>=1.10 # вместо него используем более новый pytest-testinfra
pytest-testinfra>=6.1.0 # запуск доп.тестов в molecule
python-vagrant>=0.5.15
molecule-vagrant>=0.6.1 # драйвер vagrant для molecule
```

Подробнее: https://molecule.readthedocs.io/en/latest/installation.html

Команды pip:

```bash
# Установка пакетов
python3.6 -m pip install -r requirements.txt 
# Удаление пакетов
python3.6 -m pip uninstall -r requirements.txt
# проверить зависимости
python3.6 -m pip check
# проверить установленные версии
ansible --version
molecule --version
```

Установку данных модулей рекомендуется выполнять в созданной через `virtualenv` среде работы с python. Иначе могут возникнуть проблемы с зависимостями, которые ранее были установлены в разных каталогах, указанных в переменной $PATH (от pip, pip2, pip2.7, pip3.6 и т.д).

- Выполнил инциализацию заготовки тестов `molecule` для роли `db` и провел тестирование.

```bash
# Переходим в каталог с ролью ansible
cd ansible/roles/db

# Инициализируем сценарий для уже готовой роли db (используем драйвер Vagrant)
molecule init scenario default --role-name db --driver-name vagrant

# Создаем ВМ для проверки роли
molecule create

# Проверяем название созданной ВМ для тестирования
molecule list

INFO     Running default > list
                ╷             ╷                  ╷               ╷         ╷            
  Instance Name │ Driver Name │ Provisioner Name │ Scenario Name │ Created │ Converged  
╶───────────────┼─────────────┼──────────────────┼───────────────┼─────────┼───────────╴
  instance      │ vagrant     │ ansible          │ default       │ true    │ false     

# Применяем роль ansible на ВМ (вызывается плейбук converge.yml c ролью)
molecule converge

# Подключаемся к ВМ с именем instance для отладки (после применения плейбука можно посмотреть изменения)
molecule login -h instance

# Запускаем отдельные тесты Testinfra (указаны в test_default.py):
molecule verify

INFO     default scenario test matrix: verify
INFO     Running default > verify
INFO     Executing Testinfra tests found in /home/devops-course/11-ansible4/AlBichutsky_infra/ansible/roles/db/molecule/default/tests/...
============================= test session starts ==============================
platform linux -- Python 3.6.8, pytest-6.2.2, py-1.10.0, pluggy-0.13.1
rootdir: /
plugins: testinfra-6.1.0
collected 3 items

molecule/default/tests/test_default.py ...                               [100%]

============================== 3 passed in 3.46s ===============================
INFO     Verifier completed successfully.

# Выполняем полный цикл тестирования
molecule test

# Выходим из ВМ и удаляем ее (рекомендуется запускать на локальной машине перед новым тестированием)
molecule destroy
```

- Добавил отдельную проверку, что mongoDB слушает порт 27017 (в файле test_default.py).  

```python
...
# check is MongoDB listening port 27017
def test_listening_port(host):
    mongo_socket = host.socket("tcp://0.0.0.0:27017")
    assert mongo_socket.is_listening
...
```

- В каталоге `../ansible/playbooks` создал плейбуки, которые вызывают наши роли:

packer_db.yml

```yml
- name: Configure MongoDB
  hosts: all
  become: true
  roles: 
    - db
```

packer_app.yml

```yml
- name: Configure App
  hosts: all
  become: true
  roles:
    - app    
```

Затем в шаблонах Packer настроил ansible-провижинг и указал данные плейбуки (вместо shell-провижинга). 
При этом при создании образа будут запускаться только таски каждой роли с определенными тэгами:

db.json

```json
{
    "variables": {
           "zone": "ru-central1-a",
           "instance_cores": "2"
       },
    "builders": [
       {
           "type": "yandex",
           "service_account_key_file": "{{user `service_account_key_file`}}",
           "folder_id": "{{user `folder_id`}}",
           "source_image_family": "{{user `source_image_family`}}",
           "image_name": "reddit-db-base-{{timestamp}}",
           "image_family": "reddit-base",
           "ssh_username": "ubuntu",
           "platform_id": "standard-v1",
           "zone": "{{user `zone`}}",
           "instance_cores": "{{user `instance_cores`}}",
       "use_ipv4_nat" : "true"
       }
   ],
   "provisioners": [
       {
           "type": "ansible",
           "user": "ubuntu",
           "playbook_file": "ansible/playbooks/packer_db.yml",
           "extra_arguments": ["--tags","install"],
           "ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
       }
   ]
}
```

app.json

```json
{
    "variables": {
           "zone": "ru-central1-a",
           "instance_cores": "2"
       },
    "builders": [
       {
           "type": "yandex",
           "service_account_key_file": "{{user `service_account_key_file`}}",
           "folder_id": "{{user `folder_id`}}",
           "source_image_family": "{{user `source_image_family`}}",
           "image_name": "reddit-app-base-{{timestamp}}",
           "image_family": "reddit-base",
           "ssh_username": "ubuntu",
           "platform_id": "standard-v1",
           "zone": "{{user `zone`}}",
           "instance_cores": "{{user `instance_cores`}}",
       "use_ipv4_nat" : "true"
       }
   ],
   "provisioners": [
       {
           "type": "ansible",
           "user": "ubuntu",
           "playbook_file": "ansible/playbooks/packer_app.yml",
           "extra_arguments": ["--tags","ruby"],
           "ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
       }
   ]
}
```

Билд стал проходить успешно только после того, как указал строчку `"user": "ubuntu"` в секцию `provisioners`.

Проверка запекания образа:

```bash
# Запускаем сборку образов из корневой папки проекта (не из packer).
# Это сделано, чтобы тесты github прошли успешно. 
# В шаблонах db.json, app.json путь к плейбуку и роли задается через переменную {{ pwd }}, т.е применительно к каталогу запуска команды packer
packer validate -var-file=packer/variables.json packer/db.json
packer validate -var-file=packer/variables.json packer/db.json
packer build -var-file=packer/variables.json packer/db.json
packer build -var-file=packer/variables.json packer/app.json
```

- Выполнил проверку плейбуков и ролей с помощью `ansible-lint`, затем исправил их. Из-за несоответствий формата и синтаксиса yml не проходили тесты на github.  

Описание проверяемых параметров: https://ansible-lint.readthedocs.io/en/latest/default_rules.html#meta-no-info  

Основные проблемы:  
`yaml: no new line character at the end of file (new-line-at-end-of-file)` - отутствует CRLF в конце строки  
`yaml: trailing spaces (trailing-spaces)` - наличие лишних пробелов  
`yaml: comment not indented like content (comments-indentation)` - съехали строчки с комментариями 

```bash
# Установка ansible-lint (можно добавить в requirements.txt)
python3.6 -m pip install ansible-lint
which ansible-lint
# проверка ролей (исключаем роли, которые не проверяем)
cd ansible
ansible-lint playbooks/site.yml --exclude=roles/jdauphant.nginx --exclude=.imported_roles/jdauphant.nginx --exclude=.imported_roles/db
# также можем использовать
ansible-playbook playbooks/site.yml -v.
```
