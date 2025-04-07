# According to RFC-7230, for HTTP response status we use "status reason"
# instead of status text or status message.

mate.web = web = {}

web.request = (options) -> new Promise((resolve, reject) ->
    try
        method = options.method
        uri = options.uri
        headerFields = options.headerFields ? null
        body = options.body ? null
        timeout = options.timeout ? null
        responseBodyType = options.responseBodyType ? "text"
        if not method?
            fail()
        if not uri?
            fail()
        if body? and typeof body != "string" and body not instanceof Uint8Array
            fail()
        if responseBodyType not in ["binary", "text", "json"]
            fail()
        if mate.environmentType == "browser" then do ->
            xhr = new XMLHttpRequest()
            xhr.open(method, uri)
            if headerFields?
                Object.forEach(headerFields, (key, value) -> xhr.setRequestHeader(key, value))
            xhr.responseType =
                if responseBodyType == "binary"
                    "arraybuffer"
                else if responseBodyType == "text"
                    "text"
                else if responseBodyType == "json"
                    "text"
            xhr.timeout = timeout ? 0
            xhr.onload = ->
                response =
                    statusCode: xhr.status
                    statusReason: xhr.statusText
                    headerFields:
                        xhr.getAllResponseHeaders()
                        .stripTrailingNewline()
                        .deepSplit("\r\n", ": ", 1)
                        .map((field) -> [field[0].toLowerCase(), field[1]])
                        .toObject()
                    body:
                        if responseBodyType == "binary"
                            new Uint8Array(xhr.response)
                        else if responseBodyType == "text"
                            xhr.response
                        else if responseBodyType == "json"
                            JSON.parse(xhr.response)
                if (200 <= response.statusCode < 300)
                    resolve(response)
                else
                    reject(response)
            xhr.onerror = ->
                reject(new Error())
            xhr.ontimeout = ->
                reject(new Error("timeout"))
            xhr.send(body)
        else do ->
            http = module.require("http")
            https = module.require("https")
            urlMod = module.require("url")
            parsedUri = urlMod.parse(uri)
            httpOrHttps = if parsedUri.protocol == "https:" then https else http
            rawRequest = httpOrHttps.request(
                {
                    method: method
                    hostname: parsedUri.hostname
                    port: parsedUri.port
                    path: parsedUri.path
                    headers: headerFields
                },
                (rawResponse) ->
                    data = new Buffer(0)
                    rawResponse.on("data", (chunk) ->
                        data = Buffer.concat([data, chunk])
                    )
                    rawResponse.on("end", ->
                        response =
                            statusCode: rawResponse.statusCode
                            statusReason: rawResponse.statusMessage
                            headerFields: rawResponse.headers
                            body:
                                if responseBodyType == "binary"
                                    new Uint8Array(data)
                                else if responseBodyType == "text"
                                    data.toString()
                                else if responseBodyType == "json"
                                    JSON.parse(data.toString())
                        if (200 <= response.statusCode < 300)
                            resolve(response)
                        else
                            reject(response)
                    )
            )
            if timeout?
                rawRequest.setTimeout(timeout, ->
                    rawRequest.abort()
                    reject(new Error("timeout"))
                )
            rawRequest.on("error", (e) ->
                reject(new Error())
            ).end(if body instanceof Uint8Array then new Buffer(body) else body)
    catch ex
        reject(ex)
)

web.get = (uri, options) ->
    actualOptions =
        method: "GET"
        uri: uri
    Object.assign(actualOptions, options)
    web.request(actualOptions)

web.jsonGet = (uri, options) ->
    actualOptions =
        method: "GET"
        uri: uri
        responseBodyType: "json"
    Object.assign(actualOptions, options)
    web.request(actualOptions)

web.binaryGet = (uri, options) ->
    actualOptions =
        method: "GET"
        uri: uri
        responseBodyType: "binary"
    Object.assign(actualOptions, options)
    web.request(actualOptions)

web.post = (uri, body, options) ->
    actualOptions =
        method: "POST"
        uri: uri
        body: body
    Object.assign(actualOptions, options)
    web.request(actualOptions)

web.jsonPost = (uri, body, options) ->
    actualOptions =
        method: "POST"
        uri: uri
        headerFields: {"Content-Type": "application/json"}
        body: JSON.stringify(body)
        responseBodyType: "json"
    Object.assign(actualOptions, options)
    web.request(actualOptions)
