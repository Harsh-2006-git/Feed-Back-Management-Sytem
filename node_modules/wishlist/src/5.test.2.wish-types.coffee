wishlist.Test::_check_equal = (actual, ruler, name = "") ->
    objects = [] # This variable is to avoid circular object/array.
    determine = (actual, ruler) =>
        if Array.isArray(actual) and Array.isArray(ruler)
            if actual.length == ruler.length and ruler.every((m, index) =>
                if m in objects
                    wishlist.objectIs(actual[index], m)
                else
                    objects.push(m) if typeof m == "object" and m != null
                    determine(actual[index], m)
            )
                true
            else
                false
        else if typeof actual == "object" and actual != null and
                typeof ruler == "object" and ruler != null
            if wishlist.hasSameKeys(actual, ruler) and Object.keys(ruler).every((m) =>
                if ruler[m] in objects
                    wishlist.objectIs(actual[m], ruler[m])
                else
                    objects.push(ruler[m]) if typeof ruler[m] == "object" and ruler[m] != null
                    determine(actual[m], ruler[m])
            )
                true
            else
                false
        else
            wishlist.objectIs(actual, ruler)
    result =
        type: determine(actual, ruler)
        name: name
    if result.type == false
        result.actual = wishlist.valueToMessage(actual)
        result.expected = "= " + wishlist.valueToMessage(ruler)
    result

wishlist.Test::_check_notEqual = (actual, ruler, name = "") ->
    objects = [] # This variable is to avoid circular object/array.
    determine = (actual, ruler) =>
        if Array.isArray(actual) and Array.isArray(ruler)
            if actual.length != ruler.length or ruler.some((m, index) =>
                if m in objects
                    not wishlist.objectIs(actual[index], m)
                else
                    objects.push(m) if typeof m == "object" and m != null
                    determine(actual[index], m)
            )
                true
            else
                false
        else if typeof actual == "object" and actual != null and
                typeof ruler == "object" and ruler != null
            if not wishlist.hasSameKeys(actual, ruler) or Object.keys(ruler).some((m) =>
                if ruler[m] in objects
                    not wishlist.objectIs(actual[m], ruler[m])
                else
                    objects.push(ruler[m]) if typeof ruler[m] == "object" and ruler[m] != null
                    determine(actual[m], ruler[m])
            )
                true
            else
                false
        else
            not wishlist.objectIs(actual, ruler)
    result =
        type: determine(actual, ruler)
        name: name
    if result.type == false
        result.actual = wishlist.valueToMessage(actual)
        result.expected = "≠ " + wishlist.valueToMessage(ruler)
    result

wishlist.Test::_check_is = (actual, ruler, name = "") ->
    result =
        type: wishlist.objectIs(actual, ruler)
        name: name
    if result.type == false
        result.actual = wishlist.valueToMessage(actual)
        result.expected = "is " + wishlist.valueToMessage(ruler)
    result

wishlist.Test::_check_isnt = (actual, ruler, name = "") ->
    result =
        type: not wishlist.objectIs(actual, ruler)
        name: name
    if result.type == false
        result.actual = wishlist.valueToMessage(actual)
        result.expected = "isn't " + wishlist.valueToMessage(ruler)
    result

wishlist.Test::_check_throws = (fun, ruler, name = "") ->
    passed = false
    resultType =
        try
            fun()
            passed = true
            false
        catch error
            if not ruler?
                true
            else if ruler instanceof RegExp
                if ruler.test(error.message)
                    true
                else
                    false
            else
                if error instanceof ruler
                    true
                else
                    false
    result =
        type: resultType
        name: name
    if result.type == false
        result.actual = if passed then "no exception" else "another exception"
        result.expected = if passed then "exception" else "an exception"
    result

wishlist.Test::_check_doesNotThrow = (fun, name = "") ->
    resultType =
        try
            fun()
            true
        catch
            false
    result =
        type: resultType
        name: name
    if result.type == false
        result.actual = "exception"
        result.expected = "no exception"
    result

wishlist.Test::_check_lessThan = (actual, ruler, name = "") ->
    result =
        type: actual < ruler
        name: name
    if result.type == false
        result.actual = wishlist.valueToMessage(actual)
        result.expected = "< " + wishlist.valueToMessage(ruler)
    result

wishlist.Test::_check_lessThanOrEqual = (actual, ruler, name = "") ->
    result =
        type: actual <= ruler
        name: name
    if result.type == false
        result.actual = wishlist.valueToMessage(actual)
        result.expected = "<= " + wishlist.valueToMessage(ruler)
    result

wishlist.Test::_check_greaterThan = (actual, ruler, name = "") ->
    result =
        type: actual > ruler
        name: name
    if result.type == false
        result.actual = wishlist.valueToMessage(actual)
        result.expected = "> " + wishlist.valueToMessage(ruler)
    result

wishlist.Test::_check_greaterThanOrEqual = (actual, ruler, name = "") ->
    result =
        type: actual >= ruler
        name: name
    if result.type == false
        result.actual = wishlist.valueToMessage(actual)
        result.expected = ">= " + wishlist.valueToMessage(ruler)
    result
