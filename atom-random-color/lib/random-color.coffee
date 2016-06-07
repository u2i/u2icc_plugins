{CompositeDisposable} = require 'atom'

module.exports = RandomColor =
  _isActive: false
  _timer: null
  _syntaxThemes: []

  _originalThemes: null
  _originalColor: ""
  _originalBackground: ""

  activate: ->
    @_start()

  deactivate: ->
    @_stop()

  _start: ->
    console.log 'RandomColor started!'
    if @_isActive then return
    @_isActive = true

    @_storeOriginalValues()

    @_timer = setInterval =>
      @_changeColors()
    , 3000
    @_syntaxThemes = @_getThemes('syntax')

  _stop: ->
    console.log 'RandomColor stopped!'
    unless @_isActive then return
    @_isActive = false

    clearInterval @_timer
    @_resetOriginalValues()

  serialize: ->
    isActive: @_isActive

  _changeColors: ->
    @_activateRandomSyntaxTheme()
    editors = document.querySelectorAll '.editor'
    for editor in editors
      @_setRandomColors editor

  _activateRandomSyntaxTheme: ->
    themeConfig = atom.config.get('core.themes')
    themeConfig[1] = @_pickRandomElement(@_syntaxThemes).name
    atom.config.set('core.themes', themeConfig)
    console.log "core.themes: #{atom.config.get('core.themes')}"

  _pickRandomElement: (array) ->
    array[@_randomNum(array.length)]

  _randomNum: (max) ->
    Math.floor Math.random() * max

  _setRandomColors: (editor) ->
    textRgb = [0..2].map (_) => @_randomNum(256)
    backgroundRgb = textRgb.map (val) -> (val + 128) % 256
    editor.style['color'] = "rgb(#{textRgb.join()})"
    editor.style['background'] = "rgb(#{backgroundRgb.join()})"

  _getThemes: (themeType) ->
    allThemes = atom.themes.getLoadedThemes()
    allThemes.filter (theme) -> theme.metadata.theme == themeType

  _storeOriginalValues: ->
    @_originalThemes = atom.config.get('core.themes')

    editor = document.querySelectorAll('.editor')[0]
    if editor
      @_originalColor = editor.style['color']
      @_originalBackground = editor.style['background']

  _resetOriginalValues: ->
    atom.config.set('core.themes', @_originalThemes)
    editors = document.querySelectorAll('.editor')
    for editor in editors
      editor.style['color'] = @_originalColor
      editor.style['background'] = @_originalBackground
