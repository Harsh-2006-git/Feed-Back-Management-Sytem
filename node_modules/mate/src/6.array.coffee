# In some `Array` methods, I enable the fraction format index and length for convenience.
# Except that, all `Array` methods arguments are very "strict" without any multi-use purpose.

class ArrayLazyWrapper
    constructor: (value, chainToCopy, itemToPush) ->
        @_value = value
        @_chain = (chainToCopy ? [])[..]
        @_chain.push(itemToPush) if itemToPush?
        getter(@, "length", => @force().length) # simulate `Array`'s `length`

    force: ->
        n = @_value
        for m in @_chain
            n = m.fun.apply(n, m.args)
        n

    # simulate `Array`'s methods ====================[
    map: -> @_pushChain(Array::map, arguments)
    filter: -> @_pushChain(Array::filter, arguments)
    concat: -> @_pushChain(Array::concat, arguments)
    portion: -> @_pushChain(Array::portion, arguments)
    funSort: -> @_pushChain(Array::funSort, arguments)
    funSortDescending: -> @_pushChain(Array::funSortDescending, arguments)
    funReverse: -> @_pushChain(Array::funReverse, arguments)
    except: -> @_pushChain(Array::except, arguments)
    distinct: -> @_pushChain(Array::distinct, arguments)
    union: -> @_pushChain(Array::union, arguments)
    intersect: -> @_pushChain(Array::intersect, arguments)
    group: -> @_pushChain(Array::group, arguments)
    flatten: -> @_pushChain(Array::flatten, arguments)
    random: -> @_pushChain(Array::random, arguments)

    some: -> @_unwrapAndDo(Array::some, arguments)
    every: -> @_unwrapAndDo(Array::every, arguments)
    isEmpty: -> @_unwrapAndDo(Array::isEmpty, arguments)
    at: -> @_unwrapAndDo(Array::at, arguments)
    atOrNull: -> @_unwrapAndDo(Array::atOrNull, arguments)
    atOrVoid: -> @_unwrapAndDo(Array::atOrVoid, arguments)
    contains: -> @_unwrapAndDo(Array::contains, arguments)
    first: -> @_unwrapAndDo(Array::first, arguments)
    firstOrNull: -> @_unwrapAndDo(Array::firstOrNull, arguments)
    firstOrVoid: -> @_unwrapAndDo(Array::firstOrVoid, arguments)
    last: -> @_unwrapAndDo(Array::last, arguments)
    lastOrNull: -> @_unwrapAndDo(Array::lastOrNull, arguments)
    lastOrVoid: -> @_unwrapAndDo(Array::lastOrVoid, arguments)
    single: -> @_unwrapAndDo(Array::single, arguments)
    singleOrNull: -> @_unwrapAndDo(Array::singleOrNull, arguments)
    singleOrVoid: -> @_unwrapAndDo(Array::singleOrVoid, arguments)
    withMax: -> @_unwrapAndDo(Array::withMax, arguments)
    withMin: -> @_unwrapAndDo(Array::withMin, arguments)
    max: -> @_unwrapAndDo(Array::max, arguments)
    min: -> @_unwrapAndDo(Array::min, arguments)
    sum: -> @_unwrapAndDo(Array::sum, arguments)
    average: -> @_unwrapAndDo(Array::average, arguments)
    median: -> @_unwrapAndDo(Array::median, arguments)
    product: -> @_unwrapAndDo(Array::product, arguments)
    randomOne: -> @_unwrapAndDo(Array::randomOne, arguments)
    # ]========================================

    _pushChain: (fun, args) ->
        # Must create a new wrapper to avoid side effects
        new ArrayLazyWrapper(@_value, @_chain, {fun: fun, args: args})

    _unwrapAndDo: (fun, args) -> fun.apply(@force(), args)

# If the element is a number or string, it will be more convenient
# to use the element itself without a selector.
Array._elementOrUseSelector = (element, selector) -> if selector? then selector(element) else element

Array::_ratioToIndex = (ratio) ->
    r = Math.round(ratio * @length - 0.5)
    if r <= 0 # `<=` can correct -0
        0
    else if r > @length - 1
        @length - 1
    else
        r

Array::_ratioToLength = (ratio) ->
    r = Math.round(ratio * (@length + 1) - 0.5)
    if r <= 0 # `<=` can correct -0
        0
    else if r > @length
        @length
    else
        r

Array::_reverseToIndex = (reverseIndex) ->
    @length - 1 - reverseIndex

Array::_positionToIndex = (pos) ->
    if typeof pos == "number"
        if 0 < pos < 1
            pos = {Ratio: pos}
        else if -1 < pos < 0
            pos = {Reverse: Ratio: -pos}
        else if pos < 0
            pos = {Reverse: -pos - 1}
    if typeof pos == "number"
        pos
    else if pos?.Reverse?.Ratio?
        @_reverseToIndex(@_ratioToIndex(pos.Reverse.Ratio))
    else if pos?.Reverse?
        @_reverseToIndex(pos.Reverse)
    else if pos?.Ratio?
        @_ratioToIndex(pos.Ratio)
    else
        fail()

Array::_amountToLength = (amount) ->
    if typeof amount == "number"
        if 0 < amount < 1
            amount = {Ratio: amount}
    if typeof amount == "number"
        amount
    else if amount?.Ratio?
        @_ratioToLength(amount.Ratio)
    else
        fail()

Array::clone = -> @[..]

Array::isEmpty = -> @length == 0

Array::lazy = -> ArrayLazyWrapper(@)

Array::portion = (startIndex, length, endIndex) ->
    startIndex = @_positionToIndex(startIndex)
    length = @_amountToLength(length) if length?
    endIndex = @_positionToIndex(endIndex) if endIndex?
    @slice(startIndex, if length? then startIndex + length else endIndex + 1)

Array::at = (index) ->
    index = @_positionToIndex(index)

    # useful for validating element operations like `first`, `last`
    assert(Number.isInteger(index) and 0 <= index < @length)

    @[index]

Array::atOrNull = (index) -> try @at(index) catch then null
Array::atOrVoid = (index) -> try @at(index) catch then undefined

# TODO: In TC39, there's no `contains` but `includes`.
Array::contains = (value) -> value in @

# TODO: performance
Array::first = (predicate) ->
    queryResult = if predicate? then @filter(predicate) else @
    queryResult.at(0)

Array::firstOrNull = (predicate) -> try @first(predicate) catch then null
Array::firstOrVoid = (predicate) -> try @first(predicate) catch then undefined

# TODO: performance
Array::last = (predicate) ->
    queryResult = if predicate? then @filter(predicate) else @
    queryResult.at(queryResult.length - 1)

Array::lastOrNull = (predicate) -> try @last(predicate) catch then null
Array::lastOrVoid = (predicate) -> try @last(predicate) catch then undefined

Array::single = (predicate) ->
    queryResult = if predicate? then @filter(predicate) else @
    assert(queryResult.length == 1)
    queryResult.at(0)

# In Microsoft LINQ it still throws if matched elements > 1, because I think
# it shouldn't throw. I want it more consistent.
Array::singleOrNull = (predicate) -> try @single(predicate) catch then null
Array::singleOrVoid = (predicate) -> try @single(predicate) catch then undefined

# If array length is 1, then `reduce` will return the single element. That's exactly what
# `withMax` and `withMin` are for, so we don't need to copy what we did in `sum` method.
Array::withMax = (selector) -> @reduce((a, b, index) =>
    if Array._elementOrUseSelector(a, selector) > Array._elementOrUseSelector(b, selector) then a else b
)
Array::withMin = (selector) -> @reduce((a, b, index) =>
    if Array._elementOrUseSelector(a, selector) < Array._elementOrUseSelector(b, selector) then a else b
)

Array::max = (selector) -> Array._elementOrUseSelector(@withMax(selector), selector)
Array::min = (selector) -> Array._elementOrUseSelector(@withMin(selector), selector)

Array::sum = (selector) ->
    if @length == 1
        Array._elementOrUseSelector(@first(), selector)
    else
        @reduce((a, b, index) =>
            (if index == 1 then Array._elementOrUseSelector(a, selector) else a) +
                    Array._elementOrUseSelector(b, selector)
        )

Array::average = (selector) -> @sum(selector) / @length

Array::median = (selector) ->
    sorted = @funSort(selector)
    a = sorted.at(0.5 - Number.EPSILON)
    b = sorted.at(0.5 + Number.EPSILON)
    m = Array._elementOrUseSelector(a, selector)
    n = Array._elementOrUseSelector(b, selector)
    (m + n) / 2

Array::product = (selector) ->
    if @length == 1
        Array._elementOrUseSelector(@first(), selector)
    else
        @reduce((a, b, index) =>
            (if index == 1 then Array._elementOrUseSelector(a, selector) else a) *
                    Array._elementOrUseSelector(b, selector)
        )

# These methods use sorting. For `keySelector`, note that the keys of all elements must be either
# all numbers, all booleans, or all strings. ====================[

# Why don't use {key: ..., value: ...}, but a non-intuitive array for the key-value pair?
# Because ECMAScript 6th's Map constructor only accepts the array form to denote a key-value pair.
# I don't want to break the consistency.
Array::group = (keySelector, valueSelector) ->
    if @isEmpty() then return []
    sorted = @funSort(keySelector)
    results = []
    comparedKey = Array._elementOrUseSelector(sorted.first(), keySelector)
    elements = []
    for m in sorted
        key = Array._elementOrUseSelector(m, keySelector)
        if key != comparedKey
            results.push([
                comparedKey
                Array._elementOrUseSelector(elements, valueSelector)
            ])
            comparedKey = key
            elements = []
        elements.push(m)
    results.push([
        comparedKey
        Array._elementOrUseSelector(elements, valueSelector)
    ])
    results

Array::_sort = (keySelector, isDescending) ->
    @clone().sort((a, b) =>
        a1 = Array._elementOrUseSelector(a, keySelector)
        b1 = Array._elementOrUseSelector(b, keySelector)
        if a1 < b1 then (if isDescending then 1 else -1)
        else if a1 > b1 then (if isDescending then -1 else 1)
        else 0
    )
Array::funSort = (keySelector) -> @_sort(keySelector, false)
Array::funSortDescending = (keySelector) -> @_sort(keySelector, true)
# ]========================================

Array::funReverse = -> @clone().reverse()

Array::except = (array, equalityComparer = (a, b) => a == b) ->
    @filter((m) =>
        not array.some((n) => equalityComparer(n, m))
    )
Array::distinct = (equalityComparer = (a, b) => a == b) ->
    r = []
    @forEach((m) =>
        r.push(m) if not r.some((n) => equalityComparer(n, m))
    )
    r
Array::union = (arr, equalityComparer) -> @concat(arr).distinct(equalityComparer)
Array::intersect = (arr, equalityComparer = (a, b) => a == b) ->
    r = []
    @distinct(equalityComparer).forEach((m) =>
        r.push(m) if arr.some((n) => equalityComparer(n, m))
    )
    r

Array::flatten = (level) ->
    if level <= 0
        fail()
    else
        r = []
        canContinue = false
        for m in @
            if Array.isArray(m)
                canContinue = true
                r.push(n) for n in m
            else
                r.push(m)
        if canContinue
            if level?
                if level == 1
                    r
                else
                    r.flatten(level - 1)
            else
                r.flatten()
        else
            r

Array::toObject = ->
    r = {}
    @forEach((element) =>
        r[element[0]] = element[1]
    )
    r

Array::deepJoin = (args...) ->
    if args.length <= 1
        @join(args[0])
    else
        @map((arr) => arr.deepJoin(args[..-2]...)).join(args.last())

Array::randomOne = -> @[Math.randomInt(@length)]
Array::random = (count) -> @clone().takeRandom(count)
Array::takeRandomOne = ->
    index = Math.randomInt(@length)
    r = @[index]
    @removeAt(index)
    r
Array::takeRandom = (count) ->
    count ?= @length
    count = @_amountToLength(count)
    repeat(count, => @takeRandomOne())

Array::removeAt = (index) ->
    @splice(index, 1)
    @

# remove the first, not all
Array::remove = (element) ->
    index = @indexOf(element)
    assert(index > -1)
    @removeAt(index)

# TODO: performance
Array::removeAll = (element) ->
    loop
        index = @indexOf(element)
        if index == -1 then break
        @removeAt(index)
    @

# remove the first, not all
Array::removeMatch = (predicate) ->
    index = @findIndex(predicate)
    assert(index > -1)
    @removeAt(index)

# TODO: performance
Array::removeAllMatch = (predicate) ->
    loop
        index = @findIndex(predicate)
        if index == -1 then break
        @removeAt(index)
    @
