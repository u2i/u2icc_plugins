ChallengesService = require './../lib/challenges-service'
using = require 'jasmine-data-provider'
ActionCable = require 'actioncable'

cableServerUrl = 'ws://some.host:2222'
teamToken = 'someTeamToken'
mockChallenge =
  name: 'Fourier transform'
  description: 'Rly hard one'
solutionResponseBodiesWithExpectedFeedbacks = [
  {
    responseBody:
      requestCorrect: false
      error: 'Fatal error!'
    expectedFeedback:
      success: false
      message: "Response from the server: Fatal error!"
  },
  {
    responseBody:
      requestCorrect: true
      success: true
      reason: 'correct'
    expectedFeedback:
      success: true
      message: "Solution correct!"
  },
  {
    responseBody:
      requestCorrect: true
      success: true
      reason: 'already_solved'
    expectedFeedback:
      success: true
      message: "You've already submitted a correct solution!"
  },
  {
    responseBody:
      requestCorrect: true
      success: false
      reason: 'incorrect'
    expectedFeedback:
      success: false
      message: "Solution incorrect!"
  }
]

describe 'ChallengesService', ->
  beforeEach ->
    @mockSubscription = jasmine.createSpyObj 'mockSubscription',
      ['perform', 'unsubscribe']

    @mockConsumer =
      subscriptions:
        create: jasmine.createSpy('create').andReturn @mockSubscription
      connection: jasmine.createSpyObj('connection', ['close'])

    spyOn(ActionCable, 'createConsumer').andReturn @mockConsumer

    @getRegisteredSubscriptionCallbacks = =>
      @mockConsumer.subscriptions.create.mostRecentCall.args[1]

    @challengesService = new ChallengesService(cableServerUrl, teamToken)

  describe '.constructor', ->
    it 'connects to the ActionCable server', ->
      expect(ActionCable.createConsumer).toHaveBeenCalledWith(cableServerUrl)

    it 'subscribes to AtomChannel using the team token', ->
      expect(@mockConsumer.subscriptions.create).toHaveBeenCalled()
      expect(@mockConsumer.subscriptions.create.mostRecentCall.args[0]).toEqual
        channel: 'AtomChannel'
        token: teamToken

    describe 'registering callbacks for subscription events', ->
      eventNames = ['initialized', 'connected', 'rejected', 'disconnected', 'received']

      using eventNames, (eventName) ->
        it "registers a callback for the '#{eventName}' event", ->
          callbacks = @getRegisteredSubscriptionCallbacks()
          expect(callbacks[eventName]).toBeDefined()

  describe '.destroy', ->
    it "calls 'unsubscribe' on the subscription", ->
      @challengesService.destroy()

      expect(@mockSubscription.unsubscribe).toHaveBeenCalled()

    it "calls 'close' on the connection", ->
      @challengesService.destroy()

      expect(@mockConsumer.connection.close).toHaveBeenCalled()

  describe '.getCurrentChallenge', ->
    it 'returns the challenge object if a challenge is active', ->
      @challengesService._challenge = mockChallenge
      expect(@challengesService.getCurrentChallenge()).toEqual(mockChallenge)

    it 'throws an error if no challenge is active', ->
      expect(@challengesService.getCurrentChallenge).toThrow(
        new Error("No challenge active."))

  describe '.checkSolution', ->
    it "performs 'solve_challenge' with outputs and 0 subtracted points", ->
      outputs = ['a', 'b', 'c']

      @challengesService.checkSolution outputs
      expect(@mockSubscription.perform).toHaveBeenCalledWith(
        'solve_challenge', outputs: outputs, subtractedPoints: 0)

    it "performs 'solve_challenge' with outputs and specified subtracted points", ->
      outputs = ['a', 'b', 'c']
      subtractedPoints = 50

      @challengesService.checkSolution outputs, subtractedPoints
      expect(@mockSubscription.perform).toHaveBeenCalledWith(
        'solve_challenge', outputs: outputs, subtractedPoints: subtractedPoints)

  describe '.updateSubtractedPoints', ->
    it "performs 'update_subtracted_points'", ->
      subtractedPoints = 50

      @challengesService.updateSubtractedPoints subtractedPoints
      expect(@mockSubscription.perform).toHaveBeenCalledWith(
        'update_subtracted_points', points: subtractedPoints)

  describe "behavior on subscription events", ->
    describe "executing callbacks registered with exposed methods", ->
      eventsWithCorrespondingMethods = [
        ['initialized', 'onSubscriptionInitialized'],
        ['connected', 'onConnected'],
        ['rejected', 'onRejected'],
        ['disconnected', 'onDisconnected']
      ]

      using eventsWithCorrespondingMethods, (event, method) ->
        beforeEach ->
          @executed = false
          @callback = =>
            @executed = true

        it "executes callbacks registered with '#{method}' on '#{event}'", ->
          @challengesService[method](@callback)

          @getRegisteredSubscriptionCallbacks()[event]()
          expect(@executed).toBe(true)

      it "executes callbacks on a new challenge", ->
        @challengesService.onChallengeStarted (challenge) =>
          @actualChallenge = challenge

        @getRegisteredSubscriptionCallbacks().received
          message: 'challengeStarted'
          body: mockChallenge
        expect(@actualChallenge).toEqual(mockChallenge)

      it "executes callbacks on a challenge end", ->
        @challengesService.onChallengeFinished =>
          @executed = true

        @getRegisteredSubscriptionCallbacks().received
          message: 'challengeFinished'
          body: {}
        expect(@executed).toBe(true)

      describe "executing callbacks on a solution response", ->
        using solutionResponseBodiesWithExpectedFeedbacks, (data) ->
          it "executes callbacks with correct feedback", ->
            @challengesService.onSolutionFeedback (feedback) =>
              @actualFeedback = feedback

            @getRegisteredSubscriptionCallbacks().received
              message: 'solutionResponse'
              body: data.responseBody
            expect(@actualFeedback).toEqual data.expectedFeedback

    it "performs 'send_current_challenge' on 'connected'", ->
      @getRegisteredSubscriptionCallbacks().connected()

      expect(@mockSubscription.perform).
        toHaveBeenCalledWith 'send_current_challenge'

    it "sets @_challenge on a new challenge", ->
      @getRegisteredSubscriptionCallbacks().received
        message: 'challengeStarted'
        body: mockChallenge
      expect(@challengesService._challenge).toEqual(mockChallenge)

    it 'removes @_challenge on a challenge end', ->
      @challengesService._challenge = mockChallenge

      @getRegisteredSubscriptionCallbacks().received
        message: 'challengeFinished'
        body: {}
      expect(@challengesService._challenge).toBe(null)
