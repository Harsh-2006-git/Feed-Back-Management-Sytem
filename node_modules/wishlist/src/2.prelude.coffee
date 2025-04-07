wishlist = {}
wishlist.environmentType =
    if exports? and module?.exports? and process?.execPath? and typeof process.execPath == "string" and
            process.execPath.search(/node/i) != -1
        "node"
    else if window? and navigator? and HTMLElement?
        "browser"
    else
        undefined
wishlist.moduleSystem =
    if exports? and module?.exports?
        "commonjs"
    else
        null
