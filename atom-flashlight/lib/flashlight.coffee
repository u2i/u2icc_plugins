{CompositeDisposable} = require 'atom'

module.exports = Flashlight =
  _isActive: false
  _syntaxThemes: []

  _originalThemes: null
  _originalColor: ""
  _originalBackground: ""
  moveLight: null


  activate: ->
    @_start()

  _start: ->
    if @_isActive then return
    console.log 'Flashlight started!'
    @_isActive = true

    @_flashlightEditor()

  _flashlightEditor: ->
    css = document.createElement('style')
    css.type = 'text/css'
    css.id = 'flashlight'
    styles = '.editor .lines .line * { color: #000; }'
    styles += ' .editor lines { background: transparent; }'
    styles += ' .editor .highlights * { color: #000; }'
    styles += ' .editor { color: #000; background-color: #000; background-image: url(https://s3.amazonaws.com/coding.challenge/images/flashlight.png); background-repeat: no-repeat; }'
    styles += ' atom-text-editor.editor .selection .region { background-color: #000; }'
    css.appendChild( document.createTextNode(styles) )
    document.getElementsByTagName("head")[0].appendChild(css)

    setTimeout () ->
      editor = document.querySelectorAll '.editor'
      lines = document.querySelector '.editor:nth-child(1) .lines'
      lines.style['background'] = "transparent"
      cont1 = lines.querySelector 'div:nth-child(1) > div:nth-child(1)'
      cont1.style['background'] = "transparent"
      cont2 = document.querySelector "body > atom-workspace > atom-workspace-axis > atom-workspace-axis > atom-pane-container > atom-pane > div > atom-text-editor > div > div > div.scroll-view > div.lines > div:nth-child(1) > div:nth-child(2)"
      cont2.style['background'] = "transparent"
      editor[0].addEventListener "mousemove", (e) ->
        editor[0].style['background-position'] = (e.layerX - 30)+"px "+ (e.layerY - 60)+"px"
    , 2000

  _removeSyles: ->
    fl = document.getElementById "flashlight"
    document.getElementsByTagName("head")[0].removeChild(fl)

    editor = document.querySelectorAll '.editor'
    editor[0].removeEventListener "mousemove", ""

  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'Flashlight stopped!'
    unless @_isActive then return
    @_removeSyles()
    @_isActive = false

  serialize: ->
    isActive: @_isActive
