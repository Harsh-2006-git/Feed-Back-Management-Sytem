###

The output should look something like this:

after 1
ReferenceError: jkjk is not defined
    ...
2014-08-20T07:22:06.198Z OK: 2, Exception: 0, Pending: 1
2014-08-20T07:22:07.187Z OK: 2, Exception: 0, Pending: 1
2014-08-20T07:22:08.188Z OK: 2, Exception: 0, Pending: 1
1
2
after 2
2014-08-20T07:22:09.189Z OK: 3, Exception: 0, Pending: 0

Tests OK. Wishes fulfilled. Mark: e3b0c

###

steps.push(->
    console.log("----- Flow -----")
    new Test(
    ).set((v, t) ->
        v.a = 1
    ).add(
        new Test(
        ).after((v) ->
            console.log("after 1")
            jkjk()
        )
    ).addAsync((v, t) ->
        setTimeout(->
            t.end()
        , 2500)
    ).after((v) ->
        console.log(v.a)
        v.a = 2
        console.log(v.a)
        console.log("after 2")
    ).run()
)
