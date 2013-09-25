window.instantiateICUI = (data, cb) ->
  $form = $("<form><input type='hidden' value='#{JSON.stringify(data)}' /></form>")
  $(document.body).append($form)
  $icui_elem = $form.find('input')
  $icui_elem.icui()
  cb($form.find('.icui'))
  $form.remove()