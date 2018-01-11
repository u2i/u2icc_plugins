ChallengesService = require './../lib/challenges-service'
using = require 'jasmine-data-provider'

mockChallenge =
  id: '0123456789abcdef'
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
  [challengesService, mockActionCableSubscription, onConnectedDisposable, onReceivedDisposable] = []
  [callOnConnected, callOnReceived] = [(->), ->]

  beforeEach ->
    [onConnectedDisposable, onReceivedDisposable] =
      ['onConnectedDisposable', 'onReceivedDisposable'].map (spyName) ->
        jasmine.createSpyObj spyName, ['dispose']

    mockActionCableSubscription =
      perform: jasmine.createSpy 'perform'
      onConnected: (callback) ->
        callOnConnected = callback
        onConnectedDisposable
      onReceived: (callback) ->
        callOnReceived = callback
        onReceivedDisposable
      destroy: jasmine.createSpy 'destroy'

    challengesService = new ChallengesService mockActionCableSubscription

  describe '::constructor', ->
    it "initializes the '_awaitingCurrentChallenge' field to false", ->
      expect(challengesService._awaitingCurrentChallenge).toEqual false

  describe '::destroy', ->
    it "does not call ::destroy on the subscription", ->
      challengesService.destroy()

      expect(mockActionCableSubscription.destroy).not.toHaveBeenCalled()

    it "disposes the supscription to 'connected' events", ->
      challengesService.destroy()
      expect(onConnectedDisposable.dispose).toHaveBeenCalled()

    it "disposes the supscription to 'received' events", ->
      challengesService.destroy()
      expect(onReceivedDisposable.dispose).toHaveBeenCalled()

  describe '::getCurrentChallenge', ->
    it 'returns the challenge object if a challenge is active', ->
      challengesService._challenge = mockChallenge
      expect(challengesService.getCurrentChallenge()).toEqual(mockChallenge)

    it 'throws an error if no challenge is active', ->
      expect(challengesService.getCurrentChallenge).toThrow(
        new Error("No challenge active."))

  describe '::checkSolution', ->
    it "performs 'solve_challenge' with outputs and 0 subtracted points", ->
      outputs = ['a', 'b', 'c']
      code = "console.log(solution)"
      chosenLanguage = "js"

      challengesService.checkSolution outputs, code, chosenLanguage
      expect(mockActionCableSubscription.perform).toHaveBeenCalledWith(
        'solve_challenge', outputs: outputs, subtractedPoints: 0, code: code, language: chosenLanguage)

    it "performs 'solve_challenge' with outputs and specified subtracted points", ->
      outputs = ['a', 'b', 'c']
      subtractedPoints = 50
      code = "console.log(solution)"
      chosenLanguage = "js"

      challengesService.checkSolution outputs, code, chosenLanguage, subtractedPoints
      expect(mockActionCableSubscription.perform).toHaveBeenCalledWith(
        'solve_challenge', outputs: outputs, subtractedPoints: subtractedPoints, code: code, language: chosenLanguage)

    using [true, false], (performResult) ->
      it "returns the result of perform", ->
        mockActionCableSubscription.perform.andReturn performResult
        returnValue = challengesService.checkSolution ['a']
        expect(returnValue).toEqual performResult

  describe '::updateSubtractedPoints', ->
    it "performs 'update_subtracted_points'", ->
      subtractedPoints = 50

      challengesService.updateSubtractedPoints subtractedPoints
      expect(mockActionCableSubscription.perform).toHaveBeenCalledWith(
        'update_subtracted_points', points: subtractedPoints)

    using [true, false], (performResult) ->
      it "returns the result of perform", ->
        mockActionCableSubscription.perform.andReturn performResult
        returnValue = challengesService.updateSubtractedPoints 50
        expect(returnValue).toEqual performResult

  describe "behavior on events emitted by ActionCableSubscription", ->
    it "performs 'send_current_challenge' on 'connected'", ->
      expect(mockActionCableSubscription.perform).not.toHaveBeenCalled()

      callOnConnected()

      expect(mockActionCableSubscription.perform).
        toHaveBeenCalledWith 'send_current_challenge'

    it "sets the '_awaitingCurrentChallenge' field to true on 'connected'", ->
      callOnConnected()

      expect(challengesService._awaitingCurrentChallenge).toEqual true

  describe "behavior on a 'challengeStarted' message", ->
    receiveChallengeStarted = -> callOnReceived
      message: 'challengeStarted'
      body: mockChallenge

    describe "when no challenge has been active", ->
      beforeEach ->
        challengesService._challenge = null

      it "sets the '_challenge' field", ->
        receiveChallengeStarted()
        expect(challengesService._challenge).toEqual mockChallenge

      it "resets the '_awaitingCurrentChallenge' field", ->
        challengesService._awaitingCurrentChallenge = true

        receiveChallengeStarted()
        expect(challengesService._awaitingCurrentChallenge).toEqual false

      it "executes callbacks registered with ::onChallengeStarted", ->
        [actualChallenge, onChallengeFinishedExecuted] = []
        challengesService.onChallengeStarted (challenge) ->
          actualChallenge = challenge
        challengesService.onChallengeFinished ->
          onChallengeFinishedExecuted = true

        receiveChallengeStarted()
        expect(actualChallenge).toEqual mockChallenge
        expect(onChallengeFinishedExecuted).not.toBeDefined()

    describe "when a challenge with the same id has been active", ->
      [oldChallenge] = []

      beforeEach ->
        oldChallenge = id: mockChallenge.id
        challengesService._challenge = oldChallenge

      it "does not update the '_challenge' field", ->
        receiveChallengeStarted()
        expect(challengesService._challenge).toEqual oldChallenge

      it "resets the '_awaitingCurrentChallenge' field", ->
        challengesService._awaitingCurrentChallenge = true

        receiveChallengeStarted()
        expect(challengesService._awaitingCurrentChallenge).toEqual false

      it "does not execute callbacks", ->
        [actualChallenge, executed] = []

        challengesService.onChallengeStarted (challenge) ->
          actualChallenge = challenge
        challengesService.onChallengeFinished ->
          executed = true

        receiveChallengeStarted()
        expect(actualChallenge).not.toBeDefined()
        expect(executed).not.toBeDefined()

    describe "when a challenge with a different id has been active", ->
      [oldChallenge] = []

      beforeEach ->
        oldChallenge =
          id: 'dizidisdifferent'
          name: 'Old one'
          description: 'Really old one.'
        challengesService._challenge = oldChallenge

      it "executes callbacks in a proper order", ->
        [actualChallenge, executed] = []

        challengesService.onChallengeFinished ->
          expect(actualChallenge).not.toBeDefined()
          # expect(@challengesService._challenge).toEqual
          executed = true
        challengesService.onChallengeStarted (challenge) ->
          expect(executed).toEqual true
          actualChallenge = challenge

        receiveChallengeStarted()
        expect(actualChallenge).toEqual(mockChallenge)

      it "unsets and updates the '_challenge' field", ->
        challengesService.onChallengeFinished ->
          expect(challengesService._challenge).toEqual null
        challengesService.onChallengeStarted (challenge) ->
          expect(challengesService._challenge).toEqual mockChallenge

        receiveChallengeStarted()
        expect(challengesService._challenge).toEqual mockChallenge

      it "resets the '_awaitingCurrentChallenge' field", ->
        challengesService._awaitingCurrentChallenge = true

        receiveChallengeStarted()
        expect(challengesService._awaitingCurrentChallenge).toEqual false

  describe "behavior on a 'challengeFinished' message", ->
    receiveChallengeFinished = -> callOnReceived
      message: 'challengeFinished'
      body: {id: mockChallenge.id}

    describe "when no challenge has been active", ->
      beforeEach ->
        challengesService._challenge = null

      it "does not update the '_challenge' field", ->
        receiveChallengeFinished()
        expect(challengesService._challenge).toEqual null

      it "does not execute callbacks", ->
        [executed] = []

        challengesService.onChallengeFinished ->
          executed = true
        challengesService.onChallengeStarted ->
          executed = true

        receiveChallengeFinished()
        expect(executed).not.toBeDefined()

      it "does not reset the '_awaitingCurrentChallenge' field", ->
        challengesService._awaitingCurrentChallenge = true

        receiveChallengeFinished()
        expect(challengesService._awaitingCurrentChallenge).toEqual true

    describe "when a challenge with different id has been active", ->
      [oldChallenge] = []

      beforeEach ->
        oldChallenge =
          id: 'dizidisdifferent'
          name: 'Old one'
          description: 'Really old one.'
        challengesService._challenge = oldChallenge

      it "does not unset the '_challenge' field", ->
        receiveChallengeFinished()
        expect(challengesService._challenge).toEqual oldChallenge

      it "does not execute callbacks", ->
        [executed] = []

        challengesService.onChallengeFinished ->
          executed = true
        challengesService.onChallengeStarted ->
          executed = true

        receiveChallengeFinished()
        expect(executed).not.toBeDefined()

      it "does not reset the '_awaitingCurrentChallenge' field", ->
        challengesService._awaitingCurrentChallenge = true

        receiveChallengeFinished()
        expect(challengesService._awaitingCurrentChallenge).toEqual true

    describe "when a challenge with the same id has been active", ->
      beforeEach ->
        challengesService._challenge = mockChallenge

      it "unsets the '_challenge' field", ->
        receiveChallengeFinished()
        expect(challengesService._challenge).toEqual null

      it "executes callbacks registered with ::onChallengeFinished", ->
        [executedOnChallengeFinished, executedOnChallengeStarted] = []

        challengesService.onChallengeFinished ->
          executedOnChallengeFinished = true
        challengesService.onChallengeStarted ->
          executedOnChallengeStarted = true

        receiveChallengeFinished()
        expect(executedOnChallengeFinished).toEqual true
        expect(executedOnChallengeStarted).not.toBeDefined

      it "does not reset the '_awaitingCurrentChallenge' field", ->
        challengesService._awaitingCurrentChallenge = true

        receiveChallengeFinished()
        expect(challengesService._awaitingCurrentChallenge).toEqual true

  describe "behavior on a 'noCurrentChallenge' message", ->
    receiveNoCurrentChallenge = -> callOnReceived
      message: 'noCurrentChallenge'
      body: {}

    describe "when '_challenge' and '_awaitingCurrentChallenge' are set", ->
      beforeEach ->
        challengesService._challenge = mockChallenge
        challengesService._awaitingCurrentChallenge = true

      it "unsets the '_challenge' field", ->
        receiveNoCurrentChallenge()
        expect(challengesService._challenge).toEqual null

      it "executes callbacks registered with 'onChallengeFinished'", ->
        [executedOnChallengeFinished, executedOnChallengeStarted] = []

        challengesService.onChallengeFinished =>
          executedOnChallengeFinished = true
        challengesService.onChallengeStarted =>
          executedOnChallengeStarted = true

        receiveNoCurrentChallenge()
        expect(executedOnChallengeFinished).toEqual true
        expect(executedOnChallengeStarted).not.toBeDefined()

      it "resets the '_awaitingCurrentChallenge' field", ->
        receiveNoCurrentChallenge()
        expect(challengesService._awaitingCurrentChallenge).toEqual false

    describe "when '_awaitingCurrentChallenge' not set", ->
      beforeEach ->
        challengesService._challenge = mockChallenge
        challengesService._awaitingCurrentChallenge = false

      it "does not unset the '_challenge' field", ->
        receiveNoCurrentChallenge()
        expect(challengesService._challenge).toEqual mockChallenge

      it "does not execute any callbacks", ->
        [executed] = []

        challengesService.onChallengeFinished ->
          executed = true
        challengesService.onChallengeStarted ->
          executed = true

        receiveNoCurrentChallenge()
        expect(executed).not.toBeDefined()

      it "resets the '_awaitingCurrentChallenge' field", ->
        receiveNoCurrentChallenge()
        expect(challengesService._awaitingCurrentChallenge).toEqual false

    describe "when '_awaitingCurrentChallenge' is set, and '_challenge' is null", ->
      beforeEach ->
        challengesService._challenge = null
        challengesService._awaitingCurrentChallenge = true

      it "does not change the '_challenge' field", ->
        receiveNoCurrentChallenge()
        expect(challengesService._challenge).toEqual null

      it "does not execute any callbacks", ->
        [executed] = []

        challengesService.onChallengeFinished ->
          executed = true
        challengesService.onChallengeStarted ->
          executed = true

        receiveNoCurrentChallenge()
        expect(executed).not.toBeDefined()

      it "resets the '_awaitingCurrentChallenge' field", ->
        receiveNoCurrentChallenge()
        expect(challengesService._awaitingCurrentChallenge).toEqual false

  describe "behavior on a solution response", ->
    using solutionResponseBodiesWithExpectedFeedbacks, (data) ->
      receiveSolutionResponse = -> callOnReceived
        message: 'solutionResponse'
        body: data.responseBody

      it "executes callbacks with correct feedback", ->
        [actualFeedback] = []

        challengesService.onSolutionFeedback (feedback) =>
          actualFeedback = feedback

        receiveSolutionResponse()
        expect(actualFeedback).toEqual data.expectedFeedback

  describe "behavior on a 'teamDetails' message", ->
    it "executes callbacks registered with ::onTeamDetails", ->
      [actualDetails] = []

      challengesService.onTeamDetails (details) =>
        actualDetails = details
      expectedTeamDetails = name: 'The best team in the world'

      callOnReceived
        message: 'teamDetails'
        body: expectedTeamDetails
      expect(actualDetails).toEqual expectedTeamDetails
