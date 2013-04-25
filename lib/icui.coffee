# ICUI
# ====
#
# ICUI is a user interface componenet for constructing repetion
# schedules for the Ruby [IceCube](https://github.com/seejohnrun/ice_cube)
# library.

do ($ = jQuery) ->
  # Helpers
  # -------
  Helpers = 
    # `clone` will make a copy of an object including all child object.
    clone: clone = (obj) ->
      if not obj? or typeof obj isnt 'object'
        return obj

      if obj instanceof Date
        return new Date(obj.getTime()) 

      if obj instanceof RegExp
        flags = ''
        flags += 'g' if obj.global?
        flags += 'i' if obj.ignoreCase?
        flags += 'm' if obj.multiline?
        flags += 'y' if obj.sticky?
        return new RegExp(obj.source, flags) 
      # Some care is taken to avoid cloning the parent class, 
      # as each ICUI object holds both a reference to a child objects
      # as well as to it's own parent, which could is a cyclic reference.
      if obj.parent? && obj.data?
        # A special case `__clone` parameter is passed to constructors
        # so as to be able to avoid actual initialization.
        newInstance = new obj.constructor(obj.parent, '__clone')
        newInstance.data = clone obj.data
      else
        newInstance = new obj.constructor()
      for own key of obj when key not in ['parent', 'data'] and typeof obj[key] != 'function'
        newInstance[key] = clone obj[key]

      return newInstance
    # `option` constructs an option for a select where it handles the 
    # case when to add the `selected` attribute. The third argument can
    # optionally be a function, otherwise it compare the third argument 
    # with the first and if equal mark the option as selected.
    option: (value, name, varOrFunc) ->
      if typeof varOrFunc == 'function'
        selected = varOrFunc(value)
      else
        selected = varOrFunc == value
      """<option value="#{value}"#{
        if selected then ' selected="selected"' else ""
      }>#{name}</option>""" 
    
    # `select` will genearate a `<select>` tag.
    select: (varOrFunc, obj) ->
      str = "<select>"
      str += Helpers.option value, label, varOrFunc for value, label of obj
      str + "</select>"
    
    daysOfTheWeek: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    # THis is a wrapper for the most ridicilous API in probably the whole of
    # JavaScript.
    dateFromString: (str) ->
      [date, time] = str.split(/[\sT]/)
      [y, m, d] = (parseInt(t, 10) for t in date.split('-'))
      [h, min, rest...] = (parseInt(t, 10) for t in time.split(':'))
      m = if m - 1 >= 0 then m - 1 else 11
      tz = (new Date).getTimezoneOffset()
      new Date(Date.UTC(y, m, d, h, min, 0, 0))
  
  # The Base Class
  # --------------
  #
  # Option is the class from which nearly all other classes in ICUI
  # inherit. A number of function are meant to be overriden.
  class Option
  
    constructor: (@parent, data = null) -> 
      @children = []
      @data = {}
      if data != '__clone'
        if data then @fromData(data) else @defaults()
    # `fromData` is meant as an initializer to which the relevant part
    # of the JSON representation is passed at startup.
    fromData: (data) ->
    # Defaults is the initializer used typically for instances constructed
    # as the default child of a parent.
    defaults: ->
    # When `clonable` is `true` the + button will appear.
    clonable: -> true
    # When `destroyable` is `true` the - button will appear.
    destroyable: -> @parent.children.length > 1
    # `clone` is the event handler that will insert a copy of the
    # reciever as a sibling to the reciever.
    clone: => 
      @parent.children.push Helpers.clone @
      @triggerRender()
    # `destroy` will remove the reciever from it's parents list
    # of children.
    destroy: => 
      @parent.children.splice(@parent.children.indexOf(@), 1)
      @parent.triggerRender()
    
    # Render is the code that is responsible for setting up an
    # HTML fragment and binding all the necessary UI callbacks
    # onto it. It is recommended to call super as this will make
    # all the child objects render as wall as displays the generic
    # cloning UI.
    render: -> 
      out = $ "<div></div>"
      out.append $("<span class='btn clone'>+</span>").click(@clone) if @clonable()
      out.append $("<span class='btn destroy'>-</span>").click(@destroy) if @destroyable()
      out.append @renderChildren()
      out.children() # <- get's rid of the container div
    
    renderChildren: -> c.render() for c in @children
    # This will trigger a rerender for the whole structure without needing
    # to keep a global reference to the root node.
    triggerRender: -> @parent.triggerRender()
  
  # The Root Node
  # -------------
  #
  # `Root` is meant as a singleton class (although this is not enforced).
  # It holds inside itself all other nodes and is responsible for actually
  # putting the whole structure into the DOM.
  class Root extends Option
    clonable: -> false
    destroyable: -> false
    
    constructor: ->
      super
      # The parent of the root node is the jQuerified element
      # itself, this will typically be an `<input type="hidden">`.
      # We insert our container div after it and save it into the 
      # `@target` variable.
      @parent.after "<div class='icui'></div>"
      @target = @parent.siblings('.icui').first()
    
    fromData: (d) ->
      @children.push new StartDate(@, d["start_date"])
      for k,v of d when v.length > 0 and k != "start_date"
        @children.push new TopLevel(@, {type: k, values: v})
  
    defaults: ->
      @children.push new StartDate(@)
      @children.push new TopLevel(@)
  
    triggerRender: -> @render()
  
    render: ->
      @target.html(@renderChildren())
    
    getData: ->
      data = {}
      for child in @children
        d = child.getData()
        if data[d.type]
          data[d.type] = data[d.type].concat(d.values)
        else
          data[d.type] = d.values
      data
    
  # TopLevel
  # --------
  # The `TopLevel` class let's the user pick whether he would like
  # to add or remove dates or rules.
  #
  # Each of these alternatives than spawns a default child.
  #
  # The total class diagram looks like this:
  #
  #     Root
  #     |- StartDate
  #     `- TopLevel +-
  #        |- DatePicker +-
  #        `- Rule +-
  #           `- Validation +-
  #              |- Count
  #              |- Until
  #              |- Day +-
  #              |- DayOfWeek +-
  #              |- DayOfMonth +-
  #              |- DayOfYear +-
  #              `- OffsetFromPascha +-
  class TopLevel extends Option
  
    destroyable: -> @parent.children.length > 2
  
    defaults: ->
      @data.type = 'rtimes'
      @children = [new DatePicker @]
  
    fromData: (d) ->
      @data.type = d.type
      if @data.type.match /times$/
        for v in d.values
          @children.push new DatePicker @, v
      else
        for v in d.values
          @children.push new Rule @, v
          
    getData: ->
      if @data.type.match /times$/
        values = (child.getData().time for child in @children)
        {type: @data.type, values}
      else
        values = (child.getData() for child in @children)
        {type: @data.type, values}
      
  
    render: -> 
      $el = $("""
    <div class="toplevel">Event <select>
      #{Helpers.option 1, "occurs", => @data.type.match /^r/}
      #{Helpers.option -1, "doesn't occur", => @data.type.match /^ex/}
    </select> on <select>
      #{Helpers.option 'dates', "specific dates", => @data.type.match /times$/}
      #{Helpers.option 'rules', "every", => @data.type.match /rules$/}
    </select>
    </div>
    """)
      ss = $el.find('select')
      ss.first().change (e) =>
        if e.target.value == '1'
            @data.type = @data.type.replace /^ex/, 'r'
        else
          @data.type = @data.type.replace /^r/, 'ex'
      ss.last().change (e) =>
        if e.target.value == 'dates'
          if @data.type.match /^r/
            @data.type = 'rtimes'
          else
            @data.type = 'extimes'
          @children = [new DatePicker @]
        else
          if @data.type.match /^r/
            @data.type = 'rrules'
          else
            @data.type = 'exrules'
          @children = [new Rule @]
        @triggerRender()
      $el.append super
      $el
  
  # Choosing Individual DateTimes
  # -----------------------------
  #
  # The DatePicker class allows the user to pick an individual date and
  # time. Currently it relies on HTML5 attributes to provide most of the
  # user interface, however we could probably easily extend this to use
  # something like jQuery UI.
  class DatePicker extends Option
    defaults: -> @data.time ?= new Date
    
    fromData: (d) -> @data.time = Helpers.dateFromString d
    
    getData: -> @data
    render: -> 
      $el = $("""
        <div class="DatePicker">
          <input type="date" value="#{@data.time.strftime('%Y-%m-%d')}" />
          <input type="time" value="#{@data.time.strftime('%H:%M')}" />
        </div>
      """)
      ss = $el.find('input')
      date = ss.first()
      time = ss.last()
      ss.change (e) =>
        @data.time = Helpers.dateFromString date.val() + ' ' + time.val()
      $el.append super
      $el
  
  # Picking the initial Date
  # ------------------------
  # `StartDate` is a concrete DatePicker subclass that takes care of picking
  # the initial date. The main diffrence is that it is unclonable.
  class StartDate extends DatePicker
    destroyable: -> false
    clonable: -> false
    getData: -> {type: "start_date", values: @data.time}
  
    render: ->
      $el = super
      $el.prepend("Start time")
      $el
  
  # Specifying Rules
  # ----------------
  # Rules specify a sort of generator which than validations filter out.
  # So the `YearlyRule` will generate thing which happen roughly once per
  # year.
  class Rule extends Option
  
    defaults: ->
      @data.rule_type = 'IceCube::YearlyRule'
      @children = [new Validation @]
      @data.interval = 1
    
    fromData: (d)->
      @data.rule_type = d.rule_type
      @data.interval = d.interval
      if d.count
        @children.push new Validation @, {type: 'count', value: d.count}
      if d.until
        @children.push new Validation @, {type: 'until', value: d.until}
      for k, v of d.validations
        @children.push new Validation @, {type: k, value: v}
  
    getData: ->
      validations = {}
      for child in @children when child.data.type isnt 'count' and child.data.type isnt 'until'
        for k,v of child.getData()
          validations[k] = v
      h = {rule_type: @data.rule_type, interval: @data.interval, validations}
      for child in @children when child.data.type is 'count' or child.data.type is 'until'
        for k,v of child.getData()
          h[k] = v
      h
      
    render: ->
      $el = $("""
        <div class="Rule">
          Every 
          <input type="number" value="#{@data.interval}" size="2" width="30" />
          #{Helpers.select @data.rule_type, 
          "IceCube::YearlyRule": 'years'
          "IceCube::MonthlyRule": 'months'
          "IceCube::WeeklyRule": 'weeks'
          "IceCube::DailyRule": 'days'}
        </div>
      """)
      $el.find('input').change (e) =>
        @data.interval = parseInt e.target.value
      $el.find('select').change (e) =>
        @data.rule_type = e.target.value
        @children = [new Validation @]
        @triggerRender()
      $el.append super
      $el
      
  # Validation
  # ----------
  # Validation let's the user pick what type of validation to use
  # and also agregates the arguments to the validation.
  class Validation extends Option
    defaults: ->
      @data.type = 'count'
      @children = [new Count @]
    
    fromData: (d) ->
      @data.type = d.type
      switch d.type
        when 'count' then @children.push new Count @, d.value
        when 'until' then @children.push new Until @, d.value
        when 'day'
          for v in d.value
            @children.push new Day @, v
        when 'day_of_week'
          for k,vals of d.value
            for v in vals
              @children.push new DayOfWeek @, {nth: v, day: k}
        else
          for v in d.value
            klass = @choices(d.type)
            c = new klass @, v
            @children.push c
    
    choices: (v) ->
      {
        count: Count
        until: Until
        day:   Day
        day_of_week: DayOfWeek
        day_of_month: DayOfMonth
        day_of_year: DayOfYear
        offset_from_pascha: OffsetFromPascha
      }[v]
    
    getData: ->
      key = @data.type
      value = switch key
        when 'count' then @children[0].getData()
        when 'until' then @children[0].getData()
        when 'day_of_week'
          obj = {}
          for child in @children
            [k,v] = child.getData()
            obj[k] ?= []
            obj[k].push v
          obj
        else child.getData() for child in @children
      obj = {}
      obj[key] = value
      obj
      
    destroyable: -> true
    render: ->
      str = """
      <div class="Validation">
        #{if @parent.children.indexOf(@) > 0 then "and if" else "If"} <select>
          #{Helpers.option "count", 'event occured less than', @data.type}
          #{Helpers.option "until", 'event is before', @data.type}
          #{Helpers.option "day", 'is this day of the week', @data.type}"""
      if @parent.data.rule_type in ["IceCube::YearlyRule", "IceCube::MonthlyRule"]
        str += Helpers.option "day_of_week", 'is this day of the nth week', @data.type 
        str += Helpers.option "day_of_month", 'is the nth day of the month', @data.type
      if @parent.data.rule_type is "IceCube::YearlyRule"
        str += Helpers.option "day_of_year", 'is the nth day of the year', @data.type
        str += Helpers.option "offset_from_pascha", 'is offset from Pascha', @data.type
      str += """
        </select>
      </div>
      """
      $el = $(str)
      $el.find('select').change (e) =>
        # switch e.target.value
        #          when 'count' then @children = [new Count @]
        #          when 'day' then @children = [new Day @]
        #          when 'day_of_week' then @children = [new DayOfWeek @]
        #          when 'day_of_month' then @children = [new DayOfMonth @]
        #          when 'day_of_year' then @children = [new DayOfYear @]
        #          when 'offset_from_pascha' then @children = [new OffsetFromPascha @]
        klass = @choices(e.target.value)
        @children = [new klass @]
        @data.type = e.target.value
        @triggerRender()
      $el.append super
  
  # Validation Types
  # ================
  # we have a seperate class for each type of validation that the
  # user can pick with `Validation`.
  #
  # Validation Instance
  # -------------------
  # ValidationInstance is a base class for some of the simpler
  # validation types (typically those with a single parameter). 
  class ValidationInstance extends Option
    defaults: -> @data.value = @default
    fromData: (d) -> @data.value = d
    getData: -> @data.value
    # `dataTransformer` is what transforms the string representation
    # of the UI into a js datastructure. It is by default `parseInt`.
    dataTransformer: parseInt
    default: 1
    # The `render` implementation relies on a `html` method that returns
    # an HTML string.
    render: ->
      $el = $ @html()
      $el.find('input,select').change (e) =>
        @data.value = @dataTransformer(e.target.value)
      $el.append(super)
      $el
  # Count
  # -----
  # Count will limit the maximum times an event can repeat.
  class Count extends ValidationInstance
    clonable: -> false
    html: -> """
      <div class="Count">
        <input type="number" value=#{@data.value} /> times.
      </div>
      """
  # Until
  # -----
  # Until will repeat the event until a specified date.
  class Until extends DatePicker
    getData: -> @data.time
    clonable: -> false
    destroyable: -> false
  

  # Day of Month
  # ------------
  # Day of month filters out days that are not the nth day of the month.
  class DayOfMonth extends ValidationInstance
    html: ->
      pluralize = (n) -> switch (if 10 < n < 20 then 4 else n % 10)
        when 1 then 'st'
        when 2 then 'nd'
        when 3 then 'rd'
        else 'th'
      str = """
      <div class="DayOfMonth">
        <select>"""
      for i in [1..31]
        str += Helpers.option i.toString(), "#{i}#{pluralize i}", @data.value.toString()
      str += Helpers.option "-1", "last", @data.value.toString()
      str +=  """</select> day of the month.
      </div>
      """
  # Day
  # ---
  # Day let's the user filter events occuring on particular days of the
  # week.
  class Day extends ValidationInstance
    html: ->
      str = """
      <div class="Day">
        <select>"""
      for day, i in Helpers.daysOfTheWeek
        str += Helpers.option i.toString(), day, @data.value.toString() 
      str +=  """</select>
      </div>
      """
  # Day of Week
  # -----------
  # This is the perhaps most confusing rule. It allows the user to
  # specify thing like "the 3rd sunday of the month" and so on.
  class DayOfWeek extends Option
    getData: -> [@data.day, @data.nth]
    fromData: (@data) ->
    defaults: ->
      @data.nth = 1
      @data.day = 0
    render: ->
      str = """
      <div class="DayOfWeek">
        <input type="number" value=#{@data.nth} /><span>nth</span>.
        <select>"""
      for day, i in Helpers.daysOfTheWeek
        str += Helpers.option i.toString(), day, @data.day.toString() 
      str +=  "</select></div>"
      $el = $ str
      pluralize = => $el.find('span').first().text switch @data.nth
        when 1 then 'st'
        when 2 then 'nd'
        when 3 then 'rd'
        else 'th'
      $el.find('input').change (e) =>
        @data.nth = parseInt e.target.value
        pluralize()
      $el.find('select').change (e) =>
        @data.day = parseInt e.target.value
      pluralize()
      $el.append(super)
      $el
    
  # Day of Year
  # -----------
  # Allows to specify a particular day of the year.
  class DayOfYear extends Option
    getData: -> @data.value
    fromData: (d) -> @data.value = d
    defaults: -> @data.value = 1
    render: ->
      str = """
      <div class="DayOfYear">
        <input type="number" value=#{Math.abs @data.value} /> day from the 
        <select>
          #{Helpers.option '+', 'beggening', => @data.value >= 0}
          #{Helpers.option '-', 'end', => @data.value < 0}
        </select> of the year.</div>
      """
      $el = $ str
      $el.find('input,select').change (e) =>
        @data.value = parseInt $el.find('input').val()
        @data.value *= if $el.find('select').val() == '+' then 1 else -1
      $el.append(super)
      $el
      
  # Offset from Pascha
  # ------------------
  # This class allows the user to specify dates in relation to the 
  # Orthodox celebration of Easter, Pascha.
  class OffsetFromPascha extends Option
    getData: -> @data.value
    defaults: -> @data.value = 0
    
    fromData: (d) -> @data.value = d
    
    render: ->
      str = """
      <div class="OffsetFromPascha">
        <input type="number" value=#{Math.abs @data.value} /> days 
        <select>
          #{Helpers.option '+', 'after', => @data.value >= 0}
          #{Helpers.option '-', 'before', => @data.value < 0}
        </select> Pascha.</div>
      """
      $el = $ str
      $el.find('input,select').change (e) =>
        @data.value = parseInt $el.find('input').val()
        @data.value *= if $el.find('select').val() == '+' then 1 else -1
      $el.append(super)
      $el
  
  # ICUI
  # ----
  # This is the class that is responsible for initializing the whole
  # hierarchy and also setting up the form to retrieve the correct
  # representation.
  class ICUI
    constructor: ($el) ->
      try
        @root = new Root $el, JSON.parse $el.val()
      catch e
        @root = new Root $el
      $el.parent('form').on 'submit', (e) =>
        $el.val JSON.stringify @getData()
      $el.after @root.render()
  
    getData: ->
      @root.getData()

  # The jQuery Plugin
  # -----------------
  $.fn.icui = ->
    @.each ->
      new ICUI $(@)