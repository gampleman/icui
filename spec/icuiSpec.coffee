describe "ICUI", ->
  $el = null
  $form = null
  $rep_link = null
  #icui_instance = null
  
  numberOf = (q) -> $el.find(q).length
  
  beforeEach ->
    $form = $("<form><input type='hidden' value='' /></form>")
    $(document.body).append($form)
    $form.find('input').icui()
    $el = $form.find('.icui')
    $rep_link = $($el.find("a")[1])
    
  afterEach -> $form.remove()
  
  it "should allow to enter the start date", ->
    expect(numberOf "input[type=date]").toBe(1)
    expect(numberOf "input[type=time]").toBe(1)
  
  it "should allow to add an end time", ->
    expect(numberOf "a").toBe(2)
    $end_link = $($el.find("a")[0])
    expect($end_link.text()).toBe("Add Ending Time")
    $end_link.click()
    expect(numberOf "input[type=date]").toBe(2)
    expect(numberOf "input[type=time]").toBe(2)
    expect(numberOf "a").toBe(1)
    
  it "should allow to add repetitions which default to specific dates", ->
    expect($rep_link.text()).toBe("Add Repetition")
    expect(numberOf "select").toBe(0)
    $rep_link.click()
    expect(numberOf "a").toBe(1)
    expect(numberOf "select").toBe(2)
    expect(numberOf "input[type=date]").toBe(2)
    expect(numberOf "input[type=time]").toBe(2)
    
  it "should allow to add more specific dates", ->
    $rep_link.click()
    clones = $el.find("span.btn.clone")
    expect(clones.length).toBe(2)
    expect(numberOf "span.btn.destroy").toBe(1)
    clones.last().click()
    expect(numberOf "span.btn.destroy").toBe(3)
    expect(numberOf "input[type=date]").toBe(3)
    expect(numberOf "input[type=time]").toBe(3)
  
  it "should allow to remove dates after they have been added", (done) ->
    $rep_link.click()
    $el.find("span.btn.clone").last().click()
    middle_destroy = $($el.find("span.btn.destroy")[1])
    middle_destroy.click()
    setTimeout ->
      expect(numberOf "span.btn.destroy").toBe(1)
      expect(numberOf "input[type=date]").toBe(2)
      expect(numberOf "input[type=time]").toBe(2)
      done()
    , 105
    