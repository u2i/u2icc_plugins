ActionCable = require 'actioncable'
{Emitter} = require 'atom'

module.exports =
  class ActionCableSubscription
    INITIALIZED = 'initialized'
    CONNECTED = 'connected'
    REJECTED = 'rejected'
    DISCONNECTED = 'disconnected'
    RECEIVED = 'received'

    constructor: (@cableServerUrl, @teamToken) ->
      @_emitter = new Emitter

    subscribe: ->
      @_consumer = ActionCable.createConsumer @cableServerUrl
      subscriptionParams =
        channel: 'AtomChannel',
        token: @teamToken
      @_subscription = @_consumer.subscriptions.create subscriptionParams,
        initialized: =>
          @_emitter.emit INITIALIZED
        connected: =>
          @_emitter.emit CONNECTED
        rejected: =>
          @_emitter.emit REJECTED
        disconnected: =>
          @_emitter.emit DISCONNECTED
        received: (data) =>
          @_emitter.emit RECEIVED, data

    perform: (method, data) ->
      unless @_subscription?
        throw new Error('Call ::subscribe first.')
      @_subscription.perform method, data

    onInitialized: (callback) ->
      @_emitter.on INITIALIZED, callback

    onConnected: (callback) ->
      @_emitter.on CONNECTED, callback

    onRejected: (callback) ->
      @_emitter.on REJECTED, callback

    onDisconnected: (callback) ->
      @_emitter.on DISCONNECTED, callback

    onReceived: (callback) ->
      @_emitter.on RECEIVED, callback

    destroy: ->
      @_subscription?.unsubscribe()
      @_consumer?.connection.close()
      @_emitter.dispose()
