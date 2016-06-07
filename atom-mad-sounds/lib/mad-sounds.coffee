{CompositeDisposable} = require 'atom'

BUCKET = "http://s3.amazonaws.com/coding.challenge/audio/"

AUDIO_MAD = []
for i in [1..41]
  AUDIO_MAD.push unless i >= 10 then 'audio_0000' + i + '.mp3' else 'audio_000' + i + '.mp3'

module.exports = MadSounds =
  _isActive: false
  _handleKeyUp: null

  activate: ->
    # atom.commands.add 'atom-workspace', 'mad-sounds:toggle', => @toggle()
    # console.log 'MadSounds activated!'
    @_start()

  # toggle: ->
  #   console.log 'MadSounds was toggled!'
  #   if @_isActive then @_stop() else @_start()

  _start: ->
    return if @_isActive
    @_isActive = true
    console.log 'MadSounds started!'
    @_handleKeyUp = (_) => @_playSound()
    document.addEventListener 'keyup', @_handleKeyUp

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
    document.removeEventListener 'keyup', @_handleKeyUp

  serialize: ->
    isActive: @_isActive
