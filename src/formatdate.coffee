{ floor, round } = Math
{ isArray } = Array

exports ?= this.formatdate = {}

# helpers

deep_merge = (objs...) ->
    objs = objs[0] if isArray(objs[0])
    res = {}
    for obj in objs
        for k, v of obj
            if typeof(v) is 'object' and not isArray(v)
                res[k] = deep_merge(res[k] or {}, v)
            else
                res[k] = v
    res

foldl = (object, array, worker) ->
    object = worker(object, value) for value in array
    object

sum = (array) ->
    res = 0
    res += value for value in array
    res

pad = (len, n, str="0") ->
    res = ""+n
    res = str+res while res.length < len
    res

# constants (bot changeable)

exports.options = defaults =
    update: on
    hook:
        interval: 5000 # 5 seconds
    css:
        'class': "format-date"
        formatted: "formatted-date"
        ago: "ago"
    max:
        amount: 42
        unit:   9  # century

exports.locale = locale =
    'default':"%T"
    formats:
        '%':"%"
        ' ':" "
        D:"%m/%d/%y"
        F:"%Y-%m-%d"
        h:"%b"
        n:"\n"
        r:"%I:%M:%S %p"
        R:"%H:%M"
        t:"\t"
        T:"%H:%M:%S"
    day:
        full:"Sunday Monday Tuesday Wednesday Thursday Friday Saturday".split(' ')
        abbr:"Sun Mon Tue Wed Thu Fri Sat".split(' ')
    month:
        full:"January February March April May June July August September October November December".split(' ')
        abbr:"Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split(' ')
    unit: "millisecond second minute hour day week month year decade century".split(' ')
    ago: (amount, unit, opts) ->
        opts.max ?= {}
        opts.max.unit   ?= defaults.max.unit
        opts.max.amount ?= defaults.max.amount
        # turn ago off when a special amount of special unit is reached (defaults to strftime)
        return off if unit is opts.max.unit and amount > opts.max.amount
        res = ""
        res += amount if amount > 1
        res += "a" if amount <= 1
        res += "n" if amount <= 1 and unit is 3 # hour
        res += " "+opts.locale.unit[unit]
        res = res.substr(0, res.length-1) + "ie" if amount > 1 and unit is 9 # century
        res += "s" if amount > 1
        res += " ago"


exports.formats = formats =
    '%':(_,l)-> l.formats['%']
    a: (d,l) -> l.day.abbr[d.getDay()]
    A: (d,l) -> l.day.full[d.getDay()]
    b: (d,l) -> l.month.abbr[d.getMonth()]
    B: (d,l) -> l.month.full[d.getMonth()]
    c: (d,l) -> ago d, locale:l
    C: (d  ) -> pad 2, floor(d.getFullYear()/100)
    d: (d  ) -> pad 2, d.getDate()
    D: (d,l) -> strftime(l.formats.D, d, l)
    e: (d,l) -> formats.d(d)?.replace('0', l.formats[' '])
    E: (d,l) -> # TODO Modifier: use alternative format, see below. (SU)
    F: (d,l) -> strftime(l.formats.F, d, l)
    G: (d  ) -> # TODO The ISO 8601 year with century as a decimal number. The 4-digit year corresponding to the ISO week number (see %V). This has the same format and value as %y, except that if the ISO week number belongs to the previous or next year, that year is used instead. (TZ)
    g: (d  ) -> # TODO Like %G, but without century, i.e., with a 2-digit year (00-99). (TZ)
    h: (d,l) -> strftime(l.formats.h, d, l)
    H: (d  ) -> pad 2, d.getHours()
    I: (d  ) -> h=d.getHours() or 12; pad 2, h-(h > 12 and 12 or 0)
    j: (d  ) -> pad 3, floor((d - new Date("1.1.#{d.getFullYear()}"))/(1000*60*60*24))
    k: (d,l) -> pad 2, d.getHours(), l.formats[' ']
    l: (d,l) -> h=d.getHours() or 12; pad 2, h-(h > 12 and 12 or 0), l.formats[' ']
    m: (d  ) -> pad 2, d.getMonth()+1
    M: (d  ) -> pad 2, d.getMinutes()
    n: (d,l) -> l.formats.n
    O: (d  ) -> # TODO Modifier: use alternative format, see below. (SU)
    p: (d  ) -> # TODO Either 'AM' or 'PM' according to the given time value, or the corresponding strings for the current locale. Noon is treated as 'pm' and midnight as 'am'.
    P: (d  ) -> formats.p(d)?.toLowerCase()
    r: (d,l) -> strftime(l.formats.r, d, l)
    R: (d,l) -> strftime(l.formats.R, d, l)
    s: (d  ) -> floor(d.getTime() / 1000)
    S: (d  ) -> pad 2, d.getSeconds()
    t: (d,l) -> l.formats.t
    T: (d,l) -> strftime(l.formats.T, d, l)
    u: (d  ) -> (d.getDay()+5) % 6 + 1
    U: (d  ) -> # TODO The week number of the current year as a decimal number, range 00 to 53, starting with the first Sunday as the first day of week 01. See also %V and %W.
    V: (d  ) -> # TODO The ISO 8601:1988 week number of the current year as a decimal number, range 01 to 53, where week 1 is the first week that has at least 4 days in the current year, and with Monday as the first day of the week. See also %U and %W. (SU)
    w: (d  ) -> d.getDay()
    W: (d  ) -> # TODO The week number of the current year as a decimal number, range 00 to 53, starting with the first Monday as the first day of week 01.
    x: (d  ) -> # TODO The preferred date representation for the current locale without the time.
    X: (d  ) -> # TODO The preferred time representation for the current locale without the date.
    y: (d  ) -> y=d.getFullYear(); pad 2, y-floor(y/100)*100
    Y: (d  ) -> d.getFullYear()
    z: (d  ) -> # TODO The time-zone as hour offset from GMT. Required to emit RFC 822-conformant dates (using "%a, %d %b %Y %H:%M:%S %z"). (GNU)
    Z: (d  ) -> # TODO The time zone or name or abbreviation.

# functions

exports.strftime = strftime = (text = locale.default, d = null, loc = locale) ->
    d ?= new Date
    d = new Date(d) if typeof d is 'string'
    for k, f of formats
        regex = new RegExp("%#{k}", 'g')
        text = text.replace(regex, f(d, loc)) if regex.test(text)
    text


exports.ago = ago = (dd, opts = {}) ->
    opts.locale ?= locale
    [i, x, T] = [0, 1, [1000, 60, 60, 24, 7, 30/7, 12, 10, 10]]
    i = sum(T.map( (n) -> dd >= (x *= n) ))
    x = round( dd / foldl(1, T[0...i], (a, b) -> a*b ) or 1)
    opts.locale.ago x, i, opts


exports.from_now = from_now = (date, opts = {}) ->
    return unless date
    opts.locale ?= locale
    now = new Date((new Date()).toISOString())
    date = new Date(date) if typeof date is 'string'
    ago(now - date, opts) or strftime(opts.format, date, opts.locale)


exports.hook = (elem, opts = {}) ->
    opts.css ?= {}
    opts.hook ?= {}
    opts.locale ?= locale
    opts.update ?= defaults.update
    opts.css.ago ?= defaults.css.ago
    opts.css['class'] ?= defaults.css['class']
    opts.css.formatted ?= defaults.css.formatted
    opts.hook.interval ?= defaults.hook.interval

    assimilate_elements = ->
        $(elem).find(".#{opts.css.formatted}").each ->
            el = $(this)
            format = el.attr('data-strftitle') or opts.format
            el.attr 'title', strftime format, el.attr('data-date'), opts.locale
            format = el.attr('data-strftime') or opts.format
            if el.hasClass opts.css.ago
                el.text from_now el.attr('data-date'), deep_merge opts, {format}
            else
                el.text strftime format, el.attr('data-date'), opts.locale
            return

        $(elem).find(".#{opts.css['class']}").each ->
            el = $(this)
            el.removeClass opts.css['class']
            el.addClass opts.css.formatted
            el.attr 'data-date', el.text()
            format = el.attr('data-strftitle') or opts.format
            el.attr 'title', strftime format, el.text(), opts.locale
            format = el.attr('data-strftime') or opts.format
            if el.hasClass opts.css.ago
                el.text from_now el.text(), deep_merge opts, {format}
            else
                el.text strftime format, el.text(), opts.locale
            return

    setInterval assimilate_elements, opts.hook.interval if opts.update
    do assimilate_elements

