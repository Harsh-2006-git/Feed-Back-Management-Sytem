global.compose = (functions) ->
    if arguments.length > 1 then functions = Array.from(arguments)
    ->
        args = arguments
        for m in functions
            args = [m.apply(@, args)]
        args[0]

global.fail = (errorMessage) -> throw new Error(errorMessage)

global.assert = (condition, message) -> if not condition then fail(message)

# Can `spread` and `repeat` be combined into one function? No, because:
# If we do so, then it cannot spread a function.
global.repeat = (iterator, times) ->
    if typeof iterator == "number" then [times, iterator] = [iterator, times]
    iterator() for i in [0...times]
global.spread = (value, count) ->
    value for i in [0...count]

getter = (obj, prop, fun) -> Object.defineProperty(obj, prop, {get: fun, configurable: true})
setter = (obj, prop, fun) -> Object.defineProperty(obj, prop, {set: fun, configurable: true})

# I think `eventField` can do all that `EventedObject` can do, plus support for static events.
# And it can avoid using strings so `eventField` is better. But maybe others like `EventedObject`
# so I keep both.
# ========================================[

# This function `f` is weird and hard to understand, but we must use this mechanism
# (function+object hybrid) to support cascade (chaining).
# For chaining, I mean not `obj.onAbc.bind(a).unbind(a)`, but `obj.onAbc(a).onDef(b).doSth()`.
global.eventField = ->
    f = (method, arg) ->
        if typeof method == "function"
            arg = method
            method = "bind"
        assert(typeof method == "string")
        f[method](arg)
        @
    f._listeners = []
    f.getListeners = ->
        f._listeners.clone()
    f.bind = (listener) ->
        f._listeners.push(listener) if listener not in f._listeners
        f
    f.unbind = (listener) ->
        f._listeners.removeAll(listener)
        f
    f.unbindAll = ->
        f._listeners = []
        f
    f.fire = (arg) ->
        for listener in f._listeners
            if arg?.blocksListeners then break
            listener(arg)
        f
    f

class mate.EventedObject
    constructor: ->
        @_eventList = {} # Using object to simulate a "dictionary" here is simpler than using array.
    on: (eventName, listener) ->
        @_eventList[eventName] ?= []
        @_eventList[eventName].push(listener) if listener not in @_eventList[eventName]
        @
    off: (eventName, listener) ->
        @_eventList[eventName].removeAll(listener)
        @
    fire: (eventName, arg) ->
        @_eventList[eventName] ?= []
        m(arg) for m in @_eventList[eventName]
        @
    listeners: (eventName) -> @_eventList[eventName]
# ]========================================
