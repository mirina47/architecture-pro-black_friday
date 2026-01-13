#!/bin/bash

###
echo "Инициализируем сервер конфигурации"
###

docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF

rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
EOF

sleep 10

###
echo "Инициализируем шарды"
###

echo "Инициализируем шард 1 (реплика-сет)"

docker compose exec -T shard1-1 mongosh --port 27021 --quiet <<EOF

rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id: 0, host: "shard1-1:27021", priority: 2 },
        { _id: 1, host: "shard1-2:27022", priority: 1 },
        { _id: 2, host: "shard1-3:27023", priority: 1 }
      ]
    }
);
EOF

sleep 10

echo "Инициализируем шард 2 (реплика-сет)"

docker compose exec -T shard2-1 mongosh --port 27024 --quiet <<EOF

rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id: 0, host: "shard2-1:27024", priority: 2 },
        { _id: 1, host: "shard2-2:27025", priority: 1 },
        { _id: 2, host: "shard2-3:27026", priority: 1 }
      ]
    }
  );
EOF

sleep 10

###
echo "Инициализируем роутер и наполним его тестовыми данными"
###

docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF

sh.addShard("shard1/shard1-1:27021,shard1-2:27022,shard1-3:27023");
sh.addShard("shard2/shard2-1:27024,shard2-2:27025,shard2-3:27026");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

use somedb

for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})

db.helloDoc.countDocuments()
EOF

sleep 10

###
echo "Сделаем проверку на шардах"
###

echo "Шард 1 (Primary - shard1-1):"
docker compose exec -T shard1-1 mongosh --port 27021 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

echo "Шард 1 (Secondary - shard1-2):"
docker compose exec -T shard1-2 mongosh --port 27022 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

echo "Шард 1 (Secondary - shard1-3):"
docker compose exec -T shard1-3 mongosh --port 27023 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF


echo "Шард 2 (Primary - shard2-1):"
docker compose exec -T shard2-1 mongosh --port 27024 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

echo "Шард 2 (Secondary - shard2-2):"
docker compose exec -T shard2-2 mongosh --port 27025 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

echo "Шард 2 (Secondary - shard2-3):"
docker compose exec -T shard2-3 mongosh --port 27026 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF