# `deepAssign` and `deepAbsorb` should use "merge" only when both source and target
# are non-array objects. It will look unnatural and weird to merge arrays.
#
# `deepAssign` and `deepAbsorb` must use deep clone when the source is a non-array object but
# can't be merged. If otherwise using direct assignment, then it will have severe
# side-effects: when sources are more than 1, the first or middle source's data
# may have been changed after the whole thing finishes.

Object.isObject = (x) -> typeof x in ["object", "function"] and x != null
Object.isNormalObject = (x) -> Object.isObject(x) and typeof x != "function" and not Array.isArray(x)

# TODO: need to use new concept
Object.clone = (x) ->
    y = {}
    for key in Object.keys(x)
        y[key] = x[key]
    y

Object.allKeys = (x) -> key for key of x
Object.keyValues = (x) -> Object.keys(x).map((key) -> [key, x[key]])
Object.allKeyValues = (x) -> Object.allKeys(x).map((key) -> [key, x[key]])

Object.forEach = (x, callback) -> Object.keys(x).forEach((key) -> callback(key, x[key]))
Object.forEachOfAll = (x, callback) -> Object.allKeys(x).forEach((key) -> callback(key, x[key]))

Object.deepAssign = (target, sources...) ->
    sources.forEach((source) ->
        deepAssign = (target, source) ->
            Object.forEach(source, (key, value) ->
                if Object.isObject(value) and not Array.isArray(value) and
                Object.isObject(target[key]) and not Array.isArray(target[key])
                    deepAssign(target[key], value)
                else
                    target[key] = Object.deepClone(value)
            )
        deepAssign(target, source)
    )
    target

Object.absorb = (subject, objects...) ->
    objects.forEach((object) ->
        Object.forEach(object, (key, value) -> subject[key] = value if subject[key] == undefined)
    )
    subject

Object.deepAbsorb = (subject, objects...) ->
    objects.forEach((object) ->
        deepAbsorb = (subject, object) ->
            Object.forEach(object, (key, value) ->
                if Object.isObject(value) and not Array.isArray(value) and
                Object.isObject(subject[key]) and not Array.isArray(subject[key])
                    deepAbsorb(subject[key], value)
                else
                    subject[key] = Object.deepClone(value) if subject[key] == undefined
            )
        deepAbsorb(subject, object)
    )
    subject

Object.deepClone = (x) ->
    if Object.isObject(x)
        target = if Array.isArray(x) then [] else {}
        deepCopyFrom = (target, source) ->
            Object.forEach(source, (key, value) ->
                if Object.isObject(value)
                    target[key] = if Array.isArray(value) then [] else {}
                    deepCopyFrom(target[key], value)
                else
                    target[key] = value
            )
        deepCopyFrom(target, x)
        target
    else
        x
