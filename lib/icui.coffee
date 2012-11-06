do ($ = jQuery) ->
  Helpers = 
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

      if obj.parent? && obj.data?
        newInstance = new obj.constructor(obj.parent, '__clone')
        newInstance.data = clone obj.data
      else
        newInstance = new obj.constructor()
      for own key of obj when key not in ['parent', 'data'] and typeof obj[key] != 'function'
        newInstance[key] = clone obj[key]

      return newInstance
  
    option: (value, name, variable) ->
      if typeof variable == 'Function'
        """<option value="#{value}"#{if variable(value) then ' selected="selected"' else ""}>#{name}</option>""" 
      else
        """<option value="#{value}"#{if variable == value then ' selected="selected"' else ""}>#{name}</option>"""  
    
    daysOfTheWeek: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  
    dateFromString: (str) ->
      d = new Date
      d.setTime(Date.parse(str))
      d
  

  selectedIf = (bool) -> if bool then ' selected="selected"' else ""

  class Option
  
    constructor: (@parent, data = null) -> 
      @children = []
      @data = {}
      if data != '__clone'
        if data then @fromData(data) else @defaults()
    
    fromData: (data) ->
  
    defaults: ->
    
    clonable: -> true
    
    destroyable: -> @parent.children.length > 1
  
    clone: => 
      @parent.children.push Helpers.clone @
      @triggerRender()
  
    destroy: => 
      @parent.children.splice(@parent.children.indexOf(@), 1)
      @parent.triggerRender()
  
    render: -> 
      out = $ "<div></div>"
      out.append $("<span class='btn clone'>+</span>").click(@clone) if @clonable()
      out.append $("<span class='btn destroy'>-</span>").click(@destroy) if @destroyable()
      out.append @renderChildren()
      out.children()
    
    renderChildren: -> c.render() for c in @children
  
    triggerRender: -> @parent.triggerRender()
  
  
  class Root extends Option
    clonable: -> false
    destroyable: -> false
  
    constructor: ->
      super
      #@children.push new TopLevel(@)
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
    
  
  class TopLevel extends Option
  
    clone: ->
      console.log @parent, @parent.children, @parent.children.length
      super
  
    destroyable: -> 
      console.log @parent
      @parent.children.length > 2
  
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
      <option value="1"#{selectedIf @data.type.match /^r/}>occurs</option>
      <option value="-1"#{selectedIf @data.type.match /^ex/}>doesn't occur</option>
    </select> on <select>
      <option value="dates"#{selectedIf @data.type.match /times$/}>specific dates</option>
      <option value="rule"#{selectedIf @data.type.match /rules$/}>every</option>
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
        console.log e.target.value
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

  class DatePicker extends Option
    defaults: ->
      @data.time ?= new Date
    
    fromData: (d) ->  @data.time = Helpers.dateFromString d
    
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

  class StartDate extends DatePicker
    destroyable: -> false
    clonable: -> false
    getData: -> {type: "start_date", values: @data.time}
  
    render: ->
      $el = super
      $el.prepend("Start time")
      $el
    
  class Rule extends Option
  
    defaults: ->
      @data.rule_type = 'IceCube::YearlyRule'
      @children = [new Validation @]
      @data.interval = 1
    
    fromData: (d)->
      @data.rule_type = d.rule_type
      @data.interval = d.interval
      for k, v of d.validations
        @children.push new Validation @, {type: k, value: v}
  
    getData: ->
      validations = {}
      for child in @children
        for k,v of child.getData()
          validations[k] = v
      {rule_type: @data.rule_type, interval: @data.interval, validations}
    
    render: ->
      $el = $("""
        <div class="Rule">
          Every 
          <input type="number" value="#{@data.interval}" size="2" width="30" />
          <select>
            #{Helpers.option "IceCube::YearlyRule", 'years', @data.rule_type}
            #{Helpers.option "IceCube::MonthlyRule", 'months', @data.rule_type}
            #{Helpers.option "IceCube::WeeklyRule", 'weeks', @data.rule_type}
            #{Helpers.option "IceCube::DailyRule", 'days', @data.rule_type}
          </select>
        </div>
      """)
      $el.find('input').change (e) =>
        @data.interval = parseInt e.target.value
      $el.find('select').change (e) =>
        @data.rule_type = e.target.value
        @children = [new Validation @]
        @triggerRender()
        console.log @data
      $el.append super
      $el
    
  class Validation extends Option
    defaults: ->
      @data.type = 'count'
      @children = [new Count @]
    
    fromData: (d) ->
      @data.type = d.type
      switch d.type
        when 'count' then @children.push new Count @, d.value
        when 'day'
          for v in d.value
            @children.push new Day @, v
        when 'day_of_week'
          for k,vals of d.value
            for v in vals
              @children.push new DayOfWeek @, {nth: v, day: k}
  
    getData: ->
      key = @data.type
      value = switch key
        when 'count' then @children[0].getData()
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
    
    render: ->
      str = """
      <div class="Validation">
        #{if @parent.children.indexOf(@) > 0 then "and if" else "If"} <select>
          #{Helpers.option "count", 'event occured less than', @data.type}
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
        switch e.target.value
          when 'count' then @children = [new Count @]
          when 'day' then @children = [new Day @]
          when 'day_of_week' then @children = [new DayOfWeek @]
          when 'day_of_month' then @children = [new DayOfMonth @]
          when 'day_of_year' then @children = [new DayOfYear @]
          when 'offset_from_pascha' then @children = [new OffsetFromPascha @]
        @data.type = e.target.value
        @triggerRender()
      $el.append super
  
  class ValidationInstance extends Option
    defaults: -> @data.value = @default
    fromData: (d) -> @data.value = d
    getData: -> @data.value
    dataTransformer: (a) -> a
    render: ->
      $el = $ @html()
      $el.find('input,select').change (e) =>
        @data.value = @dataTransformer(e.target.value)
      $el.append(super)
      $el
  
  class Count extends ValidationInstance
    default: 1
    clonable: -> false
    html: -> """
      <div class="Count">
        <input type="number" value=#{@data.value} /> times.
      </div>
      """

  class DayOfMonth extends ValidationInstance
    default: 1
  
    dataTransformer: parseInt
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
    
  class Day extends ValidationInstance
    default: 0

    dataTransformer: parseInt
    html: ->
      str = """
      <div class="Day">
        <select>"""
      for day, i in Helpers.daysOfTheWeek
        str += Helpers.option i.toString(), day, @data.value.toString() 
      str +=  """</select>
      </div>
      """

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
    
    
  class DayOfYear extends Option
    getData: -> @data.value
    fromData: (d) -> @data.value = d
    defaults: -> @data.value = 1
    render: ->
      str = """
      <div class="DayOfYear">
        <input type="number" value=#{Math.abs @data.value} /> day from the 
        <select>
          #{Helpers.option '+', 'beggening', -> @data.value >= 0}
          #{Helpers.option '-', 'end', -> @data.value < 0}
        </select> of the year.</div>
      """
      $el = $ str
      $el.find('input,select').change (e) =>
        @data.value = parseInt $el.find('input').val()
        @data.value *= if $el.find('select').val() == '+' then 1 else -1
      $el.append(super)
      $el
    
  class OffsetFromPascha extends Option
    getData: -> @data.value
    fromData: (d) -> @data.value = d
    defaults: -> @data.value = 0
    render: ->
      str = """
      <div class="OffsetFromPascha">
        <input type="number" value=#{Math.abs @data.value} /> days 
        <select>
          #{Helpers.option '+', 'after', -> @data.value >= 0}
          #{Helpers.option '-', 'before', -> @data.value < 0}
        </select> Pascha.</div>
      """
      $el = $ str
      $el.find('input,select').change (e) =>
        @data.value = parseInt $el.find('input').val()
        @data.value *= if $el.find('select').val() == '+' then 1 else -1
      $el.append(super)
      $el

  class ICUI
    constructor: ($el) ->
      try
        @root = new Root $el, JSON.parse $el.val()
      catch e
        console.log e, $el.val()
        @root = new Root $el
      $el.parent('form').on 'submit', (e) =>
        $el.val JSON.stringify @getData()
        console.log $el.parent('form')
        e.preventDefault()
      $el.after @root.render()
  
    getData: ->
      @root.getData()


  $.fn.icui = ->
    @.each ->
      new ICUI $(@)