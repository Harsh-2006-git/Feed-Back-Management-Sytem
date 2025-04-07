# `slashQuoteReady` indicates whether a slash is related to regex, or math division.
# `dotAffected` is to do with things like `abc  .   def`.

# I used to use regex for this parser, but nearly all JS engine cannot execute it well.
# Some report errors. Node even hangs up with CPU usage 100%. Very weird.
# Maybe it's because this regex is very complicated, and nested. So I gave it up.
wishlist.parseExpression = (expStr, envNames) ->
    expStr += " " # add a space to simplify the search pattern
    if envNames.length == 0 then return []
    regex = new RegExp("^(" + envNames.join("|") + ")[^a-zA-Z0-9_$]", "g")
    positions = []
    quote = null
    slashQuoteReady = true
    wordStarted = false
    dotAffected = false
    objectKeyReady = false
    i = 0
    while i < expStr.length - 1 # minus 1 to exclude the added space
        c = expStr[i]
        oldSlashQuoteReady = slashQuoteReady
        if quote == null
            if "a" <= c <= "z" or "A" <= c <= "Z" or "0" <= c <= "9" or
                    c == "_" or c == "$" or c == ")" or c == "]"
                slashQuoteReady = false
            else if c == " " or c == "\t" or c == "\n" or c == "\r"
            else
                slashQuoteReady = true
        oldWordStarted = wordStarted
        if quote == null
            if "a" <= c <= "z" or "A" <= c <= "Z" or "0" <= c <= "9" or
                    c == "_" or c == "$" or c == "."
                wordStarted = true
            else
                wordStarted = false
        oldDotAffected = dotAffected
        if quote == null
            if c == "."
                dotAffected = true
            else if c == " " or c == "\t" or c == "\n" or c == "\r"
            else
                dotAffected = false
        oldObjectKeyReady = objectKeyReady
        if quote == null
            if c == "{" or c == ","
                objectKeyReady = true
            else if c == " " or c == "\t" or c == "\n" or c == "\r"
            else
                objectKeyReady = false
        if c == "\"" and quote == null
            quote = "double"
            i++
        else if c == "'" and quote == null
            quote = "single"
            i++
        else if c == "/" and quote == null and oldSlashQuoteReady
            quote = "slash"
            i++
        else if (c == "\"" and quote == "double") or
                (c == "'" and quote == "single") or
                (c == "/" and quote == "slash")
            quote = null
            i++
        else if c == "\\" and quote != null
            i += 2
        else if quote == null and not oldWordStarted and not oldDotAffected and (
            "a" <= c <= "z" or "A" <= c <= "Z"
        )
            s = expStr.substr(i, 31) # limit to 31 chars for better performance (max keyword length is 30)
            if not (oldObjectKeyReady and s.search(/^([a-zA-Z0-9_$])+\s*:/) != -1) and
                    s.search(regex) != -1
                positions.push(i)
            i++
        else
            i++
    positions

wishlist.parseWish = (wishStr) ->
    parsed = null
    name = null
    [0, 1].forEach((round) ->
        quote = null
        parenthesis = 0
        bracket = 0
        brace = 0
        slashQuoteReady = true
        dotAffected = false
        i = 0
        while i < wishStr.length
            c = wishStr[i]
            oldSlashQuoteReady = slashQuoteReady
            if quote == null
                if "a" <= c <= "z" or "A" <= c <= "Z" or "0" <= c <= "9" or
                        c == "_" or c == "$" or c == ")" or c == "]"
                    slashQuoteReady = false
                else if c == " " or c == "\t" or c == "\n" or c == "\r"
                else
                    slashQuoteReady = true
            oldDotAffected = dotAffected
            if quote == null
                if c == "."
                    dotAffected = true
                else if c == " " or c == "\t" or c == "\n" or c == "\r"
                else
                    dotAffected = false
            if c == "\"" and quote == null
                quote = "double"
                i++
            else if c == "'" and quote == null
                quote = "single"
                i++
            else if c == "/" and quote == null and oldSlashQuoteReady
                quote = "slash"
                i++
            else if (c == "\"" and quote == "double") or
                    (c == "'" and quote == "single") or
                    (c == "/" and quote == "slash")
                quote = null
                i++
            else if c == "\\" and quote != null
                i += 2
            else if c == "("
                parenthesis++
                i++
            else if c == "["
                bracket++
                i++
            else if c == "{"
                brace++
                i++
            else if c == ")"
                parenthesis--
                i++
            else if c == "]"
                bracket--
                i++
            else if c == "}"
                brace--
                i++
            else if quote == null and not oldDotAffected and parenthesis == bracket == brace == 0
                if round == 0
                    if c == ":"
                        name = wishStr.substr(i + 1)
                        wishStr = wishStr.substr(0, i)
                        break
                else if round == 1
                    s = wishStr.substr(i)
                    if (match = s.match(/// ^ = ([^]+) $ ///))?
                        parsed =
                            type: "equal"
                            components: [
                                wishStr.substr(0, i)
                                match[1]
                            ]
                        break
                    else if (match = s.match(/// ^ <> ([^]+) $ ///))?
                        parsed =
                            type: "notEqual"
                            components: [
                                wishStr.substr(0, i)
                                match[1]
                            ]
                        break
                    else if (match = s.match(/// ^ \s is \s ([^]+) $ ///))?
                        parsed =
                            type: "is"
                            components: [
                                wishStr.substr(0, i)
                                match[1]
                            ]
                        break
                    else if (match = s.match(/// ^ \s isnt \s ([^]+) $ ///))?
                        parsed =
                            type: "isnt"
                            components: [
                                wishStr.substr(0, i)
                                match[1]
                            ]
                        break
                    else if (match = s.match(///^ \s throws (?: \s ([^]+))? $ ///))?
                        parsed =
                            type: "throws"
                            components: [
                                wishStr.substr(0, i)
                                if match[1]? then match[1] else "undefined"
                            ]
                        break
                    # "<=" and ">=" must precede the other two because the other two patterns
                    # also match "<=" and ">=". ====================[
                    else if (match = s.match(/// ^ <= ([^]+) $ ///))?
                        parsed =
                            type: "lessThanOrEqual"
                            components: [
                                wishStr.substr(0, i)
                                match[1]
                            ]
                        break
                    else if (match = s.match(/// ^ >= ([^]+) $ ///))?
                        parsed =
                            type: "greaterThanOrEqual"
                            components: [
                                wishStr.substr(0, i)
                                match[1]
                            ]
                        break
                    else if (match = s.match(/// ^ < ([^]+) $ ///))?
                        parsed =
                            type: "lessThan"
                            components: [
                                wishStr.substr(0, i)
                                match[1]
                            ]
                        break
                    else if (match = s.match(/// ^ > ([^]+) $ ///))?
                        parsed =
                            type: "greaterThan"
                            components: [
                                wishStr.substr(0, i)
                                match[1]
                            ]
                        break
                    # ]========================================
                i++
            else
                i++
        if round == 1
            parsed ?=
                type: "doesNotThrow"
                components: [
                    wishStr
                ]
    )
    parsed.components.push(JSON.stringify((name ? wishStr).trim()))
    parsed

wishlist.parseWishes = (wishesStr) ->
    quote = null
    parenthesis = 0
    bracket = 0
    brace = 0
    slashQuoteReady = true
    positions = []
    i = 0
    while i < wishesStr.length
        c = wishesStr[i]
        oldSlashQuoteReady = slashQuoteReady
        if quote == null
            if "a" <= c <= "z" or "A" <= c <= "Z" or "0" <= c <= "9" or
                    c == "_" or c == "$" or c == ")" or c == "]"
                slashQuoteReady = false
            else if c == " " or c == "\t" or c == "\n" or c == "\r"
            else
                slashQuoteReady = true
        if c == "\"" and quote == null
            quote = "double"
            i++
        else if c == "'" and quote == null
            quote = "single"
            i++
        else if c == "/" and quote == null and oldSlashQuoteReady
            quote = "slash"
            i++
        else if (c == "\"" and quote == "double") or
                (c == "'" and quote == "single") or
                (c == "/" and quote == "slash")
            quote = null
            i++
        else if c == "\\" and quote != null
            i += 2
        else if c == "("
            parenthesis++
            i++
        else if c == "["
            bracket++
            i++
        else if c == "{"
            brace++
            i++
        else if c == ")"
            parenthesis--
            i++
        else if c == "]"
            bracket--
            i++
        else if c == "}"
            brace--
            i++
        else if quote == null and parenthesis == bracket == brace == 0 and c == ";"
            positions.push(i)
            i++
        else
            i++
    r = []
    lastIndex = -1
    positions.forEach((index) ->
        s = wishesStr.substring(lastIndex + 1, index).trim()
        r.push(s) if s != ""
        lastIndex = index
    )
    s = wishesStr.substr(lastIndex + 1).trim()
    r.push(s) if s != ""
    r
