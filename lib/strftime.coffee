# Written by Gianni Chiappetta - gianni[at]runlevel6[dot]org
# Released under the WTFPL
if typeof Date::strftime is "undefined"
  
  ###
  Date#strftime(format) -> String
  - format (String): Formats time according to the directives in the given format string. Any text not listed as a directive will be passed through to the output string.
  
  Ruby-style date formatting. Format matchers:
  
  %a - The abbreviated weekday name (``Sun'')
  %A - The  full  weekday  name (``Sunday'')
  %b - The abbreviated month name (``Jan'')
  %B - The  full  month  name (``January'')
  %c - The preferred local date and time representation
  %d - Day of the month (01..31)
  %e - Day of the month without leading zeroes (1..31)
  %H - Hour of the day, 24-hour clock (00..23)
  %I - Hour of the day, 12-hour clock (01..12)
  %j - Day of the year (001..366)
  %k - Hour of the day, 24-hour clock w/o leading zeroes (0..23)
  %l - Hour of the day, 12-hour clock w/o leading zeroes (1..12)
  %m - Month of the year (01..12)
  %M - Minute of the hour (00..59)
  %p - Meridian indicator (``AM''  or  ``PM'')
  %P - Meridian indicator (``am''  or  ``pm'')
  %S - Second of the minute (00..60)
  %U - Week  number  of the current year,
  starting with the first Sunday as the first
  day of the first week (00..53)
  %W - Week  number  of the current year,
  starting with the first Monday as the first
  day of the first week (00..53)
  %w - Day of the week (Sunday is 0, 0..6)
  %x - Preferred representation for the date alone, no time
  %X - Preferred representation for the time alone, no date
  %y - Year without a century (00..99)
  %Y - Year with century
  %Z - Time zone name
  %z - Time zone expressed as a UTC offset (``-04:00'')
  %% - Literal ``%'' character
  
  http://www.ruby-doc.org/core/classes/Time.html#M000298
  ###
  Date::strftime = (->
    
    # 'W': week_number_from_monday,
    
    # 'Z': time_zone_name,
    
    # day
    day = (date) ->
      date.getDate() + ""
    
    # day_of_week
    day_of_week = (date) ->
      date.getDay() + ""
    
    # day_of_year
    day_of_year = (date) ->
      (((date.getTime() - cache["start_of_year"].getTime()) / day_in_ms + 1) + "").split(/\./)[0]
    
    # day_padded
    day_padded = (date) ->
      ("0" + day(date)).slice -2
    
    # default_local
    default_local = (date) ->
      date.toLocaleString()
    
    # default_local_date
    default_local_date = (date) ->
      date.toLocaleDateString()
    
    # default_local_time
    default_local_time = (date) ->
      date.toLocaleTimeString()
    
    # hour
    hour = (date) ->
      hour = date.getHours()
      if hour is 0
        hour = 12
      else hour -= 12  if hour > 12
      hour + ""
    
    # hour_24
    hour_24 = (date) ->
      date.getHours()
    
    # hour_24_padded
    hour_24_padded = (date) ->
      ("0" + hour_24(date)).slice -2
    
    # hour_padded
    hour_padded = (date) ->
      ("0" + hour(date)).slice -2
    
    # meridian
    meridian = (date) ->
      (if date.getHours() >= 12 then "pm" else "am")
    
    # meridian_upcase
    meridian_upcase = (date) ->
      meridian(date).toUpperCase()
    
    # minute
    minute = (date) ->
      ("0" + date.getMinutes()).slice -2
    
    # month
    month = (date) ->
      ("0" + (date.getMonth() + 1)).slice -2
    
    # month_name
    month_name = (date) ->
      months[date.getMonth()]
    
    # month_name_abbr
    month_name_abbr = (date) ->
      abbr_months[date.getMonth()]
    
    # second
    second = (date) ->
      ("0" + date.getSeconds()).slice -2
    
    # time_zone_offset
    time_zone_offset = (date) ->
      tz_offset = date.getTimezoneOffset()
      ((if tz_offset >= 0 then "-" else "")) + ("0" + (tz_offset / 60)).slice(-2) + ":" + ("0" + (tz_offset % 60)).slice(-2)
    
    # week_number_from_sunday
    week_number_from_sunday = (date) ->
      ("0" + Math.round(parseInt(day_of_year(date), 10) / 7)).slice -2
    
    # weekday_name
    weekday_name = (date) ->
      days[date.getDay()]
    
    # weekday_name_abbr
    weekday_name_abbr = (date) ->
      abbr_days[date.getDay()]
    
    # year
    year = (date) ->
      date.getFullYear() + ""
    
    # year_abbr
    year_abbr = (date) ->
      year(date).slice -2
    
    #------------------------------ Main ------------------------------
    strftime = (format) ->
      match = undefined
      output = format
      cache["start_of_year"] = new Date("Jan 1 " + @getFullYear())
      output = output.replace(new RegExp(match[0], "mg"), formats[match[1]](this))  if match[1] of formats  while match = regexp.exec(format)
      output
    cache = start_of_year: new Date("Jan 1 " + (new Date()).getFullYear())
    regexp = /%([a-z]|%)/g
    day_in_ms = 1000 * 60 * 60 * 24
    days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    abbr_days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    abbr_months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    formats =
      a: weekday_name_abbr
      A: weekday_name
      b: month_name_abbr
      B: month_name
      c: default_local
      d: day_padded
      e: day
      H: hour_24_padded
      I: hour_padded
      j: day_of_year
      k: hour_24
      l: hour
      m: month
      M: minute
      p: meridian_upcase
      P: meridian
      S: second
      U: week_number_from_sunday
      w: day_of_week
      x: default_local_date
      X: default_local_time
      y: year_abbr
      Y: year
      z: time_zone_offset
      "%": ->
        "%"

    strftime
  )()