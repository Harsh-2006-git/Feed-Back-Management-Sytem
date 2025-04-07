# TODO: Lots of work needed!

mate = npmMate ? require("../mate")
new Test("root"
).add((my, I) ->
    I.wish(' new Date("2014-02-03T18:19:25.987").equals(new Date("2014-02-03T18:19:25.987"))=true ')
).add((my, I) ->
    class Obj
        constructor: ->
            @onClick = eventField()
        makeClick: -> @onClick.fire()
    obj = new Obj()
    obj.onClick.bind(-> I.end())
    obj.makeClick()
).add(->
    console.logt(3)
).add("Array functional methods", (my, I) ->
    I.wish(' [3,-12,23].sum()=14 ')
    I.wish(' [3,-12,23].max()=23 ')
    I.wish(' [3,-12,23].average()=4.666666666666667 ')
    I.wish(' [3,-12,23].funSort()=[-12,3,23] ')
    I.wish(' [3,-12,23].funSortDescending()=[23,3,-12] ')
    I.wish(' [3,-12,23].funReverse()=[23,-12,3] ')
    I.wish(' [3,-12,23].at({Ratio:0})=3 ')
    I.wish(' [3,-12,23].at({Ratio:1})=23 ')
    I.wish(' [3,-12,23].at({Ratio:0.5})=-12 ')
    I.wish(' [3,-12,23].at({Ratio:1/3})=-12 ')
    I.wish(' [3,-12,23].at({Ratio:1/3-Number.EPSILON})=3 ')
    I.wish(' [3,-12,23,6].at({Ratio:0.5})=23 ')
    I.wish(' [3,-12,23,6].at({Ratio:0.5-Number.EPSILON})=-12 ')
    I.wish(' [3,-12,23,6].at(0.5)=23 ')
    I.wish(' [3,-12,23,6].at(-0.5)=-12 ')
).add("Object.deepAssign", (my, I) ->
    my.slaveSettings = {
        a: 1
        b:
            c: 5
            d: 4
        e: 8
    }
    my.masterSettings = {
        a: 2
        b:
            c: 6
            g: 3
        f: 0
    }
    Object.deepAssign(my.slaveSettings, my.masterSettings)
    I.wish("""
        slaveSettings = {
            a: 2,
            b: {
                c: 6,
                d: 4,
                g: 3
            },
            e: 8,
            f: 0
        }
    """)
).add("Object.absorb", (my, I) ->
    my.settings = {
        port: 8080
    }
    my.defaultSettings = {
        host: "127.0.0.1"
        port: 80
    }
    Object.absorb(my.settings, my.defaultSettings)
    I.wish(' settings={host:"127.0.0.1",port:8080} ')
).add("Object.deepAbsorb", (my, I) ->
    my.subjectSettings = {
        a: 1
        b:
            c: 5
            d: 4
        e: 8
    }
    my.objectSettings = {
        a: 2
        b:
            c: 6
            g: 3
        f: 0
    }
    Object.deepAbsorb(my.subjectSettings, my.objectSettings)
    I.wish("""
        subjectSettings = {
            a: 1,
            b: {
                c: 5,
                d: 4,
                g: 3
            },
            e: 8,
            f: 0
        }
    """)
).add("Object.deepClone", (my, I) ->
    my.a = {
        a: 1
        b:
            c: 5
            d: 4
        e: 8
    }
    my.b = Object.deepClone(my.a)
    I.wish(' b=a ')
    I.wish(' b isnt a ')
    I.wish(' b.b=a.b ')
    I.wish(' b.b isnt a.b ')
    my.c = {
        a: ->
        b: 7
    }
    my.c.a.m1 = 5
    my.d = Object.deepClone(my.c)
    I.wish(' d={a:{m1:5},b:7} ')
).add("cmath", (my, I) ->
    I.wish(' cmath.add("2+i","3+6i")=Point.from("5+7i") ')
    I.wish(' cmath.subtract("2+i","3+6i")=Point.from("-1-5i") ')
    I.wish(' cmath.sin("2+3i")=Point.from("9.154499146911428-4.168906959966565i") ')
).add("String", (my, I) ->
    I.wish(' "Now is {0}-{1}-{2}!".format(2000,2,3) = "Now is 2000-2-3!" ')
).run()
