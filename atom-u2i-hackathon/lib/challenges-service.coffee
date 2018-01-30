ActionCable = require 'actioncable'
{CompositeDisposable, Emitter} = require 'atom'

module.exports =
class ChallengesService
  CHALLENGE_STARTED_MESSAGE = 'challengeStarted'
  VALIDATING_SOLUTION_MESSAGE = 'validatingSolution'
  CHALLENGE_FINISHED_MESSAGE = 'challengeFinished'
  SOLUTION_RESPONSE_MESSAGE = 'solutionResponse'
  NO_CURRENT_CHALLENGE_MESSAGE = 'noCurrentChallenge'
  TEAM_DETAILS_MESSAGE = 'teamDetails'

  CHALLENGE_STARTED_EVENT = 'challengeStartedEvent'
  CHALLENGE_FINISHED_EVENT = 'challengeFinishedEvent'
  SOLUTION_RESPONSE_EVENT = 'solutionResponseEvent'
  TEAM_DETAILS_EVENT = 'teamDetailsEvent'
  VALIDATING_SOLUTION_EVENT = 'validatingSolutionEvent'

  constructor: (@_actionCableSubscription) ->
    @_emitter = new Emitter
    @_disposables = new CompositeDisposable
    @_challenge = null
    @_awaitingCurrentChallenge = false

    @_registerCallbacks()

  _registerCallbacks: ->
    @_disposables.add @_actionCableSubscription.onConnected =>
      @_actionCableSubscription.perform 'send_current_challenge'
      @_awaitingCurrentChallenge = true
    @_disposables.add @_actionCableSubscription.onReceived (data) =>
      @_actOnReceivedData data

    @onChallengeStarted (@_challenge) =>
    @onChallengeFinished =>
      @_challenge = null

  _actOnReceivedData: (data) ->
    switch data.message
      when CHALLENGE_STARTED_MESSAGE
        @_awaitingCurrentChallenge = false
        newChallenge = data.body
        if newChallenge.id != @_challenge?.id
          if @_challenge?
            @_emitter.emit CHALLENGE_FINISHED_EVENT
          @_emitter.emit CHALLENGE_STARTED_EVENT, newChallenge
      when CHALLENGE_FINISHED_MESSAGE
        if data.body.id == @_challenge?.id
          @_emitter.emit CHALLENGE_FINISHED_EVENT
      when SOLUTION_RESPONSE_MESSAGE
        @_emitter.emit SOLUTION_RESPONSE_EVENT, data.body
      when NO_CURRENT_CHALLENGE_MESSAGE
        if @_awaitingCurrentChallenge
          @_awaitingCurrentChallenge = false
          if @_challenge
            @_emitter.emit CHALLENGE_FINISHED_EVENT
      when TEAM_DETAILS_MESSAGE
        @_emitter.emit TEAM_DETAILS_EVENT, data.body
      when VALIDATING_SOLUTION_MESSAGE
        @_emitter.emit VALIDATING_SOLUTION_EVENT, data.body

  destroy: ->
    @_emitter.dispose()
    @_disposables.dispose()

  getCurrentChallenge: ->
    @_challenge || throw new Error("No challenge active.")

  checkSolution: (outputs, code, chosenLanguage, compiled, subtractedPoints = 0) ->
    @_actionCableSubscription.perform 'solve_challenge',
      outputs: outputs,
      code: code,
      language: chosenLanguage,
      compiled: compiled,
      subtractedPoints: subtractedPoints

  validateSolution: (outputs, challengeId) ->
    @_actionCableSubscription.perform 'validate_solution',
      outputs: outputs,
      challenge_id: challengeId

  updateSubtractedPoints: (points) ->
    @_actionCableSubscription.perform 'update_subtracted_points',
      points: points

  onChallengeStarted: (callback) ->
    @_emitter.on CHALLENGE_STARTED_EVENT, callback

  onValidatingSolution: (callback) ->
    @_emitter.on VALIDATING_SOLUTION_EVENT, callback

  onChallengeFinished: (callback) ->
    @_emitter.on CHALLENGE_FINISHED_EVENT, callback

  onSolutionFeedback: (callback) ->
    @_emitter.on SOLUTION_RESPONSE_EVENT, (response) =>
      callback(@_transformSolutionResponse(response))

  _transformSolutionResponse: (response) ->
    unless response.requestCorrect
      success: false
      message: "Response from the server: #{response.error}"
    else
      success: response.success
      message: @_mapReason(response.reason)

  _mapReason: (reason) ->
    switch reason
      when 'correct'
        'Solution correct!'
      when 'incorrect'
        'Solution incorrect!'
      when 'already_solved'
        "You've already submitted a correct solution!"

  onTeamDetails: (callback) ->
    @_emitter.on TEAM_DETAILS_EVENT, (teamDetails) =>
      callback(teamDetails)
