{CompositeDisposable} = require 'atom'

BUCKET = "http://s3.amazonaws.com/coding.challenge/audio/"

AUDIO_MAD = []
for i in [1..41]
  AUDIO_MAD.push unless i >= 10 then 'audio_0000' + i + '.mp3' else 'audio_000' + i + '.mp3'

module.exports = MadSounds =
  _isActive: false
  _editorEventSubscription: null
  _listeners: []
  _listener: null
  _view: null

  activate: ->
    @_start()

  _start: ->
    return if @_isActive
    @_isActive = true
    @_editorEventSubscription = atom.workspace.observeTextEditors (editor) =>
      @_view = atom.views.getView editor
      @_listener = (event) => @_handleKeyUp editor, event
      @_view.addEventListener 'keyup', @_listener
      @_listeners.push [@_view, @_listener]

  _handleKeyUp: (editor, event) ->
    @_playSound event

  _playSound: ->
    if @_isActive
      @_playAudio AUDIO_MAD[@_randomNum(41)]

  _randomNum: (max) =>
    Math.floor Math.random() * max

  _playAudio: (name) =>
    audioUrl = BUCKET + name
    audio = new Audio(audioUrl)
    console.log audio
    audio.src = audioUrl
    audio.currentTime = 0
    audio.volume = 1
    audio.play()

  deactivate: ->
    @_stop()

  _stop: ->
    return unless @_isActive
    console.log 'MadSounds stopped!'
    @_isActive = false
    @_view.removeEventListener 'keyup', @_listener
    @_listeners = []
    

  serialize: ->
    isActive: @_isActive
