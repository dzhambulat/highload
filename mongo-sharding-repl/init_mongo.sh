#!/bin/bash
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

docker compose exec -T shard1_r0 mongosh --port 27018 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
rs.initiate({_id: "shard1", members: [
{_id: 0, host: "shard1_r0:27018"},
{_id: 1, host: "shard1_r1:27022"},
{_id: 2, host: "shard1_r2:27023"}
]}) 
EOF

docker compose exec -T shard2_r0 mongosh --port 27019 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
rs.initiate({_id: "shard2", members: [
{_id: 0, host: "shard2_r0:27019"},
{_id: 1, host: "shard2_r1:27024"},
{_id: 2, host: "shard2_r2:27025"}
]}) 
EOF

docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard( "shard1/shard1_r0:27018");
sh.addShard( "shard2/shard2_r0:27019");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})
db.helloDoc.countDocuments() 
EOF
