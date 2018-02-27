{CompositeDisposable} = require 'atom'
SerialPort = require('serialport')

voltosaur_gets= 999
volts_phase = 0
voltosaur_wants= [ [50,300, '0px 30px'], [301, 600, '0px 0px'], [601, 1000, '0px -32px'] ]

VoltsView = require './views/volts-view'
voltsView = new VoltsView

module.exports = Voltosaur =
  _VoltosaurIsActive: false
  _editorEventSubscription: null
  _listeners: []
  _view: null
  _editor: null
  _listener: null

  activate: ->
    @_start()

  _start: ->
    return if @_VoltosaurIsActive
    @_VoltosaurIsActive = true

    setInterval ((e) ->
      volts_phase = Math.floor(Math.random() * 3)
      # console.log volts_phase
      return
    ), 5000

    voltsView = new VoltsView
    @voltsPanel = atom.workspace.addTopPanel
      item: voltsView.getElement()

    port = new SerialPort('/dev/tty.usbserial-AI054BZM',
      baudRate: 9600
      autoOpen: false)
    port.on 'error', (err) ->
      console.log 'Error: ', err.message
      return
    port.open (err) ->
      if err
        return console.log('Error opening port: ', err.message)
      port.flush()
      return
    port.on 'readable', (data) ->
      setTimeout (->
        data = port.read()
        if data[0] == 255 and data[1] == 255
          voltosaur_gets = (data[2] + data[3] * 255)
        port.flush()
        return
      ), 250
      # console.log voltosaur_gets
      voltsView.element.style.backgroundPosition = voltosaur_wants[volts_phase][2]
      voltsView.element.children[0].style.bottom = (voltosaur_gets / 10)+"px"
      return


    @_editorEventSubscription = atom.workspace.observeTextEditors (editor) =>
      @_view = atom.views.getView editor
      @_editor = atom.views.getView editor

      @_listener = (event) => @_handleKeyDown editor, event
      @_view.addEventListener 'keydown', @_listener
      @_listeners.push [@_view, @_listener]
    

  _handleKeyDown: (editor, event) ->
    # console.log voltosaur_gets
    # console.log editor
    # console.log event
    
    # console.log event.keyCode

    unless event.keyCode == 17 or event.keyCode == 18 or event.keyCode == 19 or event.keyCode == 16 or event.keyCode == 37 or event.keyCode == 38 or event.keyCode == 39 or event.keyCode == 40 or event.keyCode == 8 or event.keyCode == 9 or event.keyCode == 91 or event.keyCode == 93 or event.keyCode == 13 or event.keyCode == 20 or event.keyCode == 27
        if voltosaur_gets < voltosaur_wants[volts_phase][1] && voltosaur_gets > voltosaur_wants[volts_phase][0]
          return true
        else
          setTimeout ((e) ->
            editor.backspace()
            return
          ), 100

          return false

  _checkIfVoltosaurIsHappy: ->
    console.log 'is voltosaur happy?'
    
    
    # editors = document.querySelectorAll '.editor.is-focused'
    # for editor in editors
      # editor.style['font-size'] = @_randomNum(80) + 'px'



  deactivate: ->
    @_stop()

  _stop: ->
    console.log 'Voltosaur stopped!'
    unless @_VoltosaurIsActive then return
    @_view.removeEventListener 'keydown', @_listener
    @_listeners = []
    @_VoltosaurIsActive = false

  serialize: ->
    isActive: @_VoltosaurIsActive
