###

The output should look something like this:

2014-07-13T15:13:23.707Z OK: 1, Exception: 0, Pending: 0

Tests OK. Wishes fulfilled. Mark: e3b0c

###

steps.push(->
    console.log("----- Tiny -----")
    new Test().run()
)
