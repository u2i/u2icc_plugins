ActionCable = require 'actioncable'
{Disposable} = require 'atom'
using = require 'jasmine-data-provider'

ActionCableSubscription = require '../lib/action-cable-subscription'

cableServerUrl = 'ws://some.host:2222'
teamToken = 'someTeamToken'

describe 'ActionCableSubscription', ->
  [mockSubscription, mockConsumer, actionCableSubscription] = []

  getRegisteredSubscriptionCallbacks = ->
    mockConsumer?.subscriptions.create.mostRecentCall.args[1]

  beforeEach ->
    mockSubscription = jasmine.createSpyObj 'mockSubscription',
      ['perform', 'unsubscribe']

    mockConsumer =
      subscriptions:
        create: jasmine.createSpy('create').andReturn mockSubscription
      connection: jasmine.createSpyObj('connection', ['close'])

    spyOn(ActionCable, 'createConsumer').andReturn mockConsumer

    actionCableSubscription = new ActionCableSubscription cableServerUrl, teamToken

  describe '::constructor', ->
    it 'defers the connection to the server until ::subscribe is called', ->
      expect(ActionCable.createConsumer).not.toHaveBeenCalled()

  describe '::subscribe', ->
    it 'connects to the ActionCable server', ->
      actionCableSubscription.subscribe()
      expect(ActionCable.createConsumer).toHaveBeenCalledWith(cableServerUrl)

    it 'subscribes to AtomChannel using the team token', ->
      actionCableSubscription.subscribe()
      expect(mockConsumer.subscriptions.create).toHaveBeenCalled()
      expect(mockConsumer.subscriptions.create.mostRecentCall.args[0]).toEqual
        channel: 'AtomChannel'
        token: teamToken

  describe '::destroy', ->
    describe 'when ::subscribe has been called before', ->
      beforeEach ->
        actionCableSubscription.subscribe()
        actionCableSubscription.destroy()

      it "calls ::unsubscribe on the subscription", ->
        expect(mockSubscription.unsubscribe).toHaveBeenCalled()

      it "calls ::close on the connection", ->
        expect(mockConsumer.connection.close).toHaveBeenCalled()

    describe 'when ::subscribe has not been called before', ->
      it 'does not throw', ->
        expect(-> actionCableSubscription.destroy()).not.toThrow()

      it "does not call ::unsubscribe on the subscription", ->
        actionCableSubscription.destroy()
        expect(mockSubscription.unsubscribe).not.toHaveBeenCalled()

      it "does not call ::close on the connection", ->
        actionCableSubscription.destroy()
        expect(mockConsumer.connection.close).not.toHaveBeenCalled()

  describe '::perform', ->
    describe 'when ::subscribe has not been called before', ->
      it 'throws an error', ->
        expect(-> actionCableSubscription.perform 'method', data: {}).toThrow(
          new Error('Call ::subscribe first.'))

    describe 'when ::subscribe has been called before', ->
      beforeEach ->
        actionCableSubscription.subscribe()

      it 'calls ::perform on the subscription', ->
        [method, data] = ['some_method', {a: 1}]
        actionCableSubscription.perform method, data
        expect(mockSubscription.perform).toHaveBeenCalledWith method, data

      using [true, false], (performResult) ->
        it "returns the result of ::perform", ->
          mockSubscription.perform.andReturn performResult
          returnValue = actionCableSubscription.perform 'method'
          expect(returnValue).toEqual performResult

  eventsWithCorrespondingMethods = [
    ['initialized', 'onInitialized'],
    ['connected', 'onConnected'],
    ['rejected', 'onRejected'],
    ['disconnected', 'onDisconnected']
  ]

  testReturnsDisposable = (event, method) ->
    callCount = 0
    callback = -> ++callCount

    disposable = actionCableSubscription[method](callback)
    expect(disposable.constructor.name).toEqual(Disposable.name)

    actionCableSubscription.subscribe()
    getRegisteredSubscriptionCallbacks()[event]()
    disposable.dispose()
    getRegisteredSubscriptionCallbacks()[event]()
    expect(callCount).toEqual 1

  using eventsWithCorrespondingMethods, (event, method) ->
    describe "::#{method}", ->
      it "registers a callback to be called on a(n) '#{event}' event", ->
        callbackExecuted = false
        callback = -> callbackExecuted = true
        actionCableSubscription[method](callback)

        actionCableSubscription.subscribe()
        getRegisteredSubscriptionCallbacks()[event]()
        expect(callbackExecuted).toBe true

      it "returns a Disposable that can be used to cancel the callback subscription", ->
        testReturnsDisposable event, method

  describe '::onReceived', ->
    it "registers a callback to be called on a 'received' event", ->
      [actualData] = []
      callback = (data) -> actualData = data
      expectedData = {a: 1, b: 2}

      actionCableSubscription.onReceived callback

      actionCableSubscription.subscribe()
      getRegisteredSubscriptionCallbacks().received expectedData
      expect(actualData).toBe expectedData

    it "returns a Disposable that can be used to cancel the callback subscription", ->
      testReturnsDisposable 'received', 'onReceived'
