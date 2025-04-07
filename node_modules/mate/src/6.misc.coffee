JSON.clone = (x) -> JSON.parse(JSON.stringify(x))

Date::add = (x) -> # `x` must be a number
    new Date(@ - (-x))

Date::subtract = (x) -> # `x` can be a number or `Date` instance
    if typeof x == "number"
        new Date(@ - x)
    else
        @ - x

Date::equals = (x) -> x <= @ <= x

console.logt = -> console.log.apply(console, [new Date().toISOString()].concat(Array.from(arguments)))
