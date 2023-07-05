import Mix.Config
config :backend_stuff_api, port: 4000
config :backend_stuff_api, mongo_url: "mongodb://root:example@localhost:27017/"
config :backend_stuff_api, database: "backend_stuff_api_db"
config :backend_stuff_api, pool_size: 3
config :backend_stuff_api, :c, username: "root", password: "example"

# config :amqp,
#   connections: [
#     myconn: [url: "amqp://rabbit:rabbit@APILOT-AwWQ6pBk:12345"]
#   ],
#   channels: [
#     mychan: [connection: :myconn]
#   ]
