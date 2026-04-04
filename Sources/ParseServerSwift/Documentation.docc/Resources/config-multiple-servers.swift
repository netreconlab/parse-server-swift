let configuration = try ParseServerConfiguration(
    app: app,
    hostName: "localhost",
    port: 8081,
    applicationId: "applicationId",
    primaryKey: "primaryKey",
    webhookKey: "webhookKey",
    parseServerURLStrings: [
        "http://parse1:1337/parse",
        "http://parse2:1337/parse"
    ]
)
