#! /bin/bash

# находим публичные IP-адреса хостов в YC
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
      "example_var": "values"
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

