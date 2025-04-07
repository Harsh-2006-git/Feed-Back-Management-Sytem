Number.isFraction = (x) -> typeof x == "number" and isFinite(x) and Math.floor(x) != x

Number.parseFloatExt = (s) -> parseFloat(s) * (if s.endsWith("%") then 0.01 else 1)

Number::approxEquals = (x) -> Math.approxEquals(@valueOf(), x)
Number::approxGreaterThan = (x) -> Math.approxGreaterThan(@valueOf(), x)
Number::approxLessThan = (x) -> Math.approxLessThan(@valueOf(), x)

Number::pad = (integerSize, fractionalSize) ->
    @valueOf().format(
        integerSize: integerSize
        fractionalSize: fractionalSize
    )

Number::format = (options) ->
    integerSize = options?.integerSize ? 1
    fractionalSize = options?.fractionalSize ? 0
    forcesSign = options?.forcesSign ? false
    radix = options?.radix ? 10
    integerGroupEnabled = options?.integerGroupEnabled ? false
    integerGroupSeparator = options?.integerGroupSeparator ? ","
    integerGroupSize = options?.integerGroupSize ? 3
    fractionalGroupEnabled = options?.fractionalGroupEnabled ? false
    fractionalGroupSeparator = options?.fractionalGroupSeparator ? " "
    fractionalGroupSize = options?.fractionalGroupSize ? 3
    if radix != 10
        fractionalSize = 0
    x = @valueOf()
    if integerSize > 80 or fractionalSize > 20 or x >= 1e21 or x <= -1e21 or
    integerGroupSize < 1 or fractionalGroupSize < 1
        fail("Number or argument out of range")
    s =
        if radix == 10
            t = Math.roundDecimal(x, fractionalSize).toString()
            ePos = t.indexOf("e")
            if ePos == -1
                t
            else
                if t[ePos + 1] == "+"
                    fail("Number too large") # Redundant but needed to be robust
                else
                    # JavaScript shows any number < 0.000001 in exponential form, so we
                    # use `toFixed` to disable the exponential form.
                    # But `toFixed` can't be used for all cases, because
                    # `(12345678901.2).toFixed(6)` will give "12345678901.200001",
                    # which looks ugly.
                    x.toFixed(fractionalSize)
        else
            Math.round(x).toString(radix)
    isNegative = s[0] == "-"
    if s[0] == "+" or s[0] == "-" then s = s.remove(0)
    do =>
        pos = s.indexOf(".")
        rawIntegerSize = if pos == -1 then s.length else pos
        integerMissing = Math.max(integerSize - rawIntegerSize, 0)
        rawFractionalSize = if pos == -1 then 0 else s.length - 1 - pos
        fractionalMissing = fractionalSize - rawFractionalSize

        # For truncating. If `fractionalMissing` is negative then truncate, otherwise it
        # will remain unchanged.
        s = s.substr(0, s.length + fractionalMissing)
        if s[s.length - 1] == "." then s = s.substr(0, s.length - 1)

        if pos == -1 and fractionalSize > 0 then s += "."
        s = "0".repeat(integerMissing) + s + "0".repeat(Math.max(fractionalMissing, 0))
    if integerGroupEnabled or fractionalGroupEnabled then do =>
        pos = s.indexOf(".")

        # All these inserts must be from bottom to top, otherwise it will be harder
        # to locate the position to insert to.
        if fractionalGroupEnabled
            fractionalStart = (if pos == -1 then s.length else pos) + 1 + fractionalGroupSize
            (i for i in [fractionalStart..s.length - 1] by fractionalGroupSize)
            .funReverse()
            .forEach((i) => s = s.insert(i, fractionalGroupSeparator))
        if integerGroupEnabled
            integerStart = (if pos == -1 then s.length else pos) - integerGroupSize
            (i for i in [integerStart..1] by -integerGroupSize)
            .forEach((i) => s = s.insert(i, integerGroupSeparator))
    if forcesSign
        if isNegative
            s = "-" + s
        else
            s = "+" + s
    else
        if isNegative
            s = "-" + s
    s
