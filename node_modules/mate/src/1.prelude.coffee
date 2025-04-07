mate = {}
mate.packageInfo = require("./package.json")
mate.environmentType =
    if process?.execPath? and typeof process.execPath == "string" and process.execPath.search(/node/i) != -1
        "node"
    else if window? and navigator? and HTMLElement?
        "browser"
    else
        undefined
if mate.environmentType == "browser"
    window.global = window
global.npmMate = mate
global.Test = require("wishlist").Test
