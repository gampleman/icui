describe "ICUI", ->
  $el = null
  $form = null
  $rep_link = null
  #icui_instance = null
  
  beforeEach ->
    $form = $("<form><input type='hidden' value='' /></form>")
    $(document.body).append($form)
    $form.find('input').icui()
    $el = $form.find('.icui')
    $rep_link = $($el.find("a")[1])
    
  afterEach ->
    $form.remove()
  
  it "should allow to enter the start date", ->
    expect($el.find("input[type=date]").length).toBe(1)
    expect($el.find("input[type=time]").length).toBe(1)
  
  it "should allow to add an end time", ->
    expect($el.find("a").length).toBe(2)
    $end_link = $($el.find("a")[0])
    expect($end_link.text()).toBe("Add Ending Time")
    $end_link.click()
    expect($el.find("input[type=date]").length).toBe(2)
    expect($el.find("input[type=time]").length).toBe(2)
    expect($el.find("a").length).toBe(1)
    
  it "should allow to add repetitions which default to specific dates", ->
    expect($rep_link.text()).toBe("Add Repetition")
    expect($el.find("select").length).toBe(0)
    $rep_link.click()
    expect($el.find("a").length).toBe(1)
    expect($el.find("select").length).toBe(2)
    expect($el.find("input[type=date]").length).toBe(2)
    expect($el.find("input[type=time]").length).toBe(2)
    
  it "should allow to add more specific dates", ->
    $rep_link.click()
    clones = $("span.btn.clone")
    expect(clones.length).toBe(2)
    expect($("span.btn.destroy").length).toBe(1)
    clones.last().click()
    expect($("span.btn.destroy").length).toBe(3)
    expect($el.find("input[type=date]").length).toBe(3)
    expect($el.find("input[type=time]").length).toBe(3)
  
  it "should allow to remove dates after they have been added", (done) ->
    $rep_link.click()
    $("span.btn.clone").last().click()
    middle_destroy = $($("span.btn.destroy")[1])
    console.log middle_destroy
    middle_destroy.click()
    setTimeout ->
        expect($("span.btn.destroy").length).toBe(1)
        expect($el.find("input[type=date]").length).toBe(2)
        expect($el.find("input[type=time]").length).toBe(2)
        done()
    , 105
    