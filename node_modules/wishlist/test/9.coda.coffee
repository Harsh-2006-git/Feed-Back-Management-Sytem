stepIndex = -1
stepsTimer = setInterval(->
    if wishlist.currentRootTest == null
        if stepIndex == steps.length - 1
            clearInterval(stepsTimer)
        else
            stepIndex++
            steps[stepIndex]()
, 10)
