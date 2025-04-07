# This file provides compatibility among various browsers and server-side platforms such as node.

# ES6 removes `String::contains`. But we should keep it for compatibility.
if String::contains == undefined
    String::contains = String::includes

# Only IE natively supports this.
if global.setImmediate == undefined
    global.setImmediate = (callback, args) -> setTimeout(callback, 0, args)

# Only IE natively supports this.
if global.clearImmediate == undefined
    global.clearImmediate = clearTimeout
