###
In `wishlist.Test`, the `wishes` property contains only separated wishes
(i.e. not including those defined and checked in a test function), but
the `wishResults` property includes results for all wishes.
Test names can be duplicate. Wish names can also be duplicate.
Restriction: On browser it doesn't work well with exceptional tests.
###

class wishlist.Test
    # `allCount` and `endedCount` refer to all descendant tests including itself.
    # Both are redundant, but needed (for performance)
    constructor: (@name = "") ->
        @_children = []
        @fun = =>
        @afterFun = =>
        @wishes = []
        @async = false
        @parent = null
        @allCount = 1
        @_resetContext()
    _resetContext: ->
        @env = {}
        @wishResults = []
        @result = null
        @endedCount = 0

    # syntax: set([name], fun, [wishes], [options])
    set: ->
        name = fun = wishes = rawWishes = options = undefined
        normalizeWishes = (raw) =>
            combined =
                if Array.isArray(raw)
                    raw.join(";")
                else if typeof raw == "string"
                    raw
                else
                    ""
            wishlist.parseWishes(combined)
        if typeof arguments[0] == "string"
            name = arguments[0]
            fun = arguments[1]
            if typeof arguments[2] == "object" and arguments[2] != null and
                    not Array.isArray(arguments[2])
                options = arguments[2]
            else
                rawWishes = arguments[2]
                options = arguments[3]
        else
            fun = arguments[0]
            if typeof arguments[1] == "object" and arguments[1] != null and
                    not Array.isArray(arguments[1])
                options = arguments[1]
            else
                rawWishes = arguments[1]
                options = arguments[2]
        wishes = normalizeWishes(rawWishes)
        options ?= {}
        if name != undefined then @name = name
        @fun = fun
        if rawWishes != undefined then @wishes = wishes
        if options.async != undefined then @async = options.async
        @

    setAsync: ->
        args = []
        for m in arguments
            args.push(m)
        lastArg = args[args.length - 1]
        if typeof lastArg == "object" and lastArg != null and not Array.isArray(lastArg)
            lastArg.async = true
        else
            args.push({async: true})
        @set(args...)

    after: (@afterFun) ->
        @

    add: ->
        newChild = null
        count = null
        if arguments[0] instanceof wishlist.Test
            newChild = arguments[0]
            count = newChild.getAll().length
        else
            newChild = new wishlist.Test()
            newChild.set(arguments...)
            count = 1
        newChild.parent = @
        @_children.push(newChild)
        @getAncestorsAndSelf().forEach((test) => test.allCount += count)
        @

    addAsync: ->
        args = []
        for m in arguments
            args.push(m)
        lastArg = args[args.length - 1]
        if typeof lastArg == "object" and lastArg != null and not Array.isArray(lastArg)
            lastArg.async = true
        else
            args.push({async: true})
        @add(args...)

    getChildren: ->
        # use a shallow copy to encapsule `_children` to prevent direct operation on the array
        @_children[..]

    getAncestors: ->
        test = @
        r = []
        while test.parent != null
            r.push(test.parent)
            test = test.parent
        r

    getAncestorsAndSelf: ->
        [@].concat(@getAncestors())

    # all descendant tests including itself
    getAll: ->
        r = []
        r.push(@)
        traverse = (test) =>
            test.getChildren().forEach((m) =>
                r.push(m)
                traverse(m)
            )
        traverse(@)
        r

    run: (isRoot = true) ->
        if isRoot
            wishlist.currentRootTest = @
        @_resetContext()
        if @parent?
            @env = wishlist.objectClone(@parent.env)

        # We use `setTimeout(..., 0)` only to make all tests "unordered", at least theoretically.
        setTimeout(=>
            if wishlist.environmentType == "node"
                domain = require("domain").create()
                domain.on("error", (error) =>
                    @end(
                        type: false
                        errorMessage: """
                            Error Name: #{error.name}
                            Error Message: #{error.message}
                            Error Stack: #{error.stack}
                        """
                    )
                )
                domain.run(=> process.nextTick(=>
                    @fun(@env, @)
                    if not @result? and not @async
                        @end({type: true})
                ))
            else
                try
                    @fun(@env, @)
                    if not @result? and not @async
                        @end({type: true})
                catch
                    @end({type: false})
        , 0)

        if isRoot
            allTests = @getAll()
            console.log()

            # TODO: Scanning for timeout is now also in this function. It's inaccurate because interval
            # is 1 sec. We may need to create another timer with shorter interval for that.
            timerJob = =>
                okTests = allTests.filter((m) => m.result? and m.result.type == true)
                exceptionTests = allTests.filter((m) => m.result? and m.result.type == false)
                pendingTests = allTests.filter((m) => not m.result?)
                console.log("#{new Date().toISOString()} OK: #{okTests.length}, " +
                        "Exception: #{exceptionTests.length}, Pending: #{pendingTests.length}")
                if pendingTests.length == 0
                    clearInterval(timer)
                    exceptionTests.forEach((m) =>
                        console.log("\n********** Exceptional Test **********")
                        console.log("Test: #{m.name}")
                        console.log("Function: #{m.fun.toString()}")
                        console.log(m.result.errorMessage) if m.result.errorMessage?
                    )
                    failureCount = 0
                    successCount = 0
                    markString = ""
                    allTests.forEach((m) => m.wishResults.forEach((n) =>
                        markString += " " + n.type.toString()
                        if n.type == false
                            failureCount++
                            ancestors = m.getAncestors()
                            ancestors.reverse()
                            longName = ancestors.concat([m]).map((m) => m.name).join(" --> ")
                            console.log("\n********** Broken Wish **********")
                            console.log("    Test: #{longName}")
                            console.log("    Wish: #{n.name}")
                            console.log("Expected: #{n.expected}")
                            console.log("  Actual: #{n.actual}")
                        else
                            successCount++
                    ))
                    markString = markString.trim()
                    mark = wishlist.sha256(markString).substr(0, 5)
                    console.log("\n" + (
                        (
                            if exceptionTests.length == 0
                                "Tests OK."
                            else
                                "#{exceptionTests.length} tests of #{allTests.length} exceptional."
                        ) + " " +
                        (
                            if failureCount == 0
                                "Wishes fulfilled."
                            else
                                "#{failureCount} wishes of #{failureCount + successCount} broken."
                        ) + " " +
                        "Mark: #{mark}"
                    ) + "\n")
                    wishlist.currentRootTest = null

            timer = setInterval(timerJob, 1000)

            # a delay slightly greater than 0 is useful for preventing a useless heartbeat
            # while there's no async test and computation takes very little time.
            setTimeout(timerJob, 10)
        @

    end: (result) ->
        if not @result?
            @result = result ? {type: true}
            @wishes.forEach((m) =>
                @_checkWish(m)
            )
            @getAncestorsAndSelf().forEach((test) =>
                test.endedCount++
                if test.endedCount == test.allCount
                    test._tryCallFun(=> test.afterFun(test.env))
            )
            @getChildren().forEach((m) =>
                m.run(false)
            )
        @

    _tryCallFun: (fun) ->
        if wishlist.environmentType == "node"
            domain = require("domain").create()
            domain.on("error", (error) =>
                console.log(error.stack)
            )
            domain.run(=> process.nextTick(fun))
        else
            try
                fun()
            catch
                console.log("Error!")

    _checkWish: (wishStr) ->
        # Reason for `that`: CoffeeScript cannot detect `this` keyword in `eval` string,
        # so in `eval` in fat arrow functions we must use `that`.
        that = this

        interpret = (s) =>
            wishlist.parseExpression(s, Object.keys(@env)).forEach((m, index) =>
                insertedString = "that.env."
                pos = m + insertedString.length * index
                s = s.substr(0, pos) + insertedString + s.substr(pos)
            )
            s
        parsed = wishlist.parseWish(wishStr)
        args = parsed.components.map((m, index) =>
            if index == parsed.components.length - 1
                m
            else
                interpret(m)
        )
        name = JSON.parse(args[args.length - 1])
        result =
            try
                # Must enclose it by "()", otherwise object literals can't be evaluated.
                # Note: Ideally a single "()" pair is enough, but Safari has a strange bug
                # that makes `eval("(-0)")` return +0. So we must use "(())" to workaround it.
                args = args.map((m) => eval("((#{m}))"))

                @["_check_" + parsed.type](args...)
            catch
                type: false
                name: name
                actual: "unknown"
                expected: "unknown"
        @wishResults.push(result)

    wish: (wishesStr) ->
        wishlist.parseWishes(wishesStr).forEach((wishStr) =>
            @_checkWish(wishStr)
        )
