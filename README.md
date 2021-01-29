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

1-е задание:

- Установил 'ansible' на локальной машине.  
- Запустил инфраструктуру `terraform` из окружения `stage`, описанную в прошлом ДЗ:

```bash
cd terraform/stage
terraform plan
terraform apply
```
- Создал конфигурационный файл `ansible.cfg` с необходимыми параметрами

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

`inventory` (в INI-формате)  

```
[app] # название группы
appserver ansible_host=178.154.230.247 # хост

[db] # название группы
dbserver ansible_host=178.154.231.113 # хост
```

`inventory.yml` (в YAML-формате)  

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

- Создал и выполнил playbook

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
Команда для запуска сценария `playbook`

```bash
ansible-playbook clone.yml
```

После повторного выполнения сценария наблюдаем вывод:

```
PLAY RECAP ******************************************************************************************************************************
appserver                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Изменеия не произошли. Это происходит, т.к. `ansible` выполняет сценарии с использованием модулей идемпотентно, т.е