{CompositeDisposable, Emitter} = require 'atom'

module.exports =
  class KeystrokeCounter

    constructor: ->
      @_bufferSubscriptionsById = {}
      @_workspaceSubscription = null
      @_count = 0
      @_intervals = []
      @_emitter = new Emitter

    start: ->
      unless @_workspaceSubscription?
        @_setCount(0)
        @_workspaceSubscription = atom.workspace.observeTextEditors (editor) =>
          @observeBuffer editor.getBuffer()

    _setCount: (newCount) ->
      @_count = newCount
      @_emitter.emit 'change', newCount

    stop: ->
      @_intervals.forEach (interval) -> clearInterval(interval)
      @_intervals = []
      @_workspaceSubscription?.dispose()
      @_workspaceSubscription = null
      for _, bufferSubscription of @_bufferSubscriptionsById
        bufferSubscription.dispose()
      @_bufferSubscriptionsById = {}

    reportCountPeriodically: (interval, callback) ->
      @_intervals.push setInterval =>
        callback(@_count)
      , interval

    reportCountOnChange: (callback) ->
      @_emitter.on 'change', (newCount) ->
        callback(newCount)

    getCount: ->
      @_count

    observeBuffer: (buffer) ->
      unless buffer.id of @_bufferSubscriptionsById
        bufferSubscriptions = new CompositeDisposable
        bufferSubscriptions.add buffer.onDidChange (event) =>
          if event.oldText != event.newText
            @_setCount(@_count + 1)
        bufferSubscriptions.add buffer.onDidDestroy =>
          bufferSubscriptions.dispose()
        @_bufferSubscriptionsById[buffer.id] = bufferSubscriptions

    destroy: ->
      @stop()
      @_emitter.dispose()
