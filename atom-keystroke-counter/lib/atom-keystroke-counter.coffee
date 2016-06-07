AtomKeystrokeCounterView = require './atom-keystroke-counter-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomKeystrokeCounter =
  atomKeystrokeCounterView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @atomKeystrokeCounterView = new AtomKeystrokeCounterView(state.atomKeystrokeCounterViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atomKeystrokeCounterView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-keystroke-counter:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomKeystrokeCounterView.destroy()

  serialize: ->
    atomKeystrokeCounterViewState: @atomKeystrokeCounterView.serialize()

  toggle: ->
    console.log 'AtomKeystrokeCounter was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
