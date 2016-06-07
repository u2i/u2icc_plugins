ActionCable = require 'actioncable'
{Emitter} = require 'atom'

module.exports =
class ChallengesService
  CONNECTED = 'connected'
  DISCONNECTED = 'disconnected'
  INITIALIZED = 'initialized'
  REJECTED = 'rejected'
  CHALLENGE_STARTED = 'challengeStarted'
  CHALLENGE_FINISHED = 'challengeFinished'
  SOLUTION_RESPONSE = 'solutionResponse'

  _challenge: null

  constructor: (cableServerUrl, teamToken) ->
    @_emitter = new Emitter

    @onConnected =>
      @_cableSubscription.perform 'send_current_challenge'
    @onChallengeStarted (@_challenge) =>
    @onChallengeFinished =>
      @_challenge = null

    @_cable = ActionCable.createConsumer cableServerUrl
    params =
      channel: 'AtomChannel'
      token: teamToken
    @_cableSubscription = @_cable.subscriptions.create params,
      initialized: =>
        @_emitter.emit INITIALIZED
      connected: =>
        @_emitter.emit CONNECTED
      rejected: =>
        @_emitter.emit REJECTED
      disconnected: =>
        @_emitter.emit DISCONNECTED
      received: (data) =>
        @_emitter.emit data.message, data.body

  destroy: ->
    @_cableSubscription.unsubscribe()
    @_cable.connection.close()
    @_emitter.dispose()

  getCurrentChallenge: ->
    if @_challenge?
      @_challenge
    else
      throw new Error("No challenge active.")

  checkSolution: (outputs, subtractedPoints = 0) ->
    @_cableSubscription.perform 'solve_challenge',
      outputs: outputs,
      subtractedPoints: subtractedPoints

  updateSubtractedPoints: (points) ->
    @_cableSubscription.perform 'update_subtracted_points',
      points: points

  onChallengeStarted: (callback) ->
    @_emitter.on CHALLENGE_STARTED, callback
    @

  onChallengeFinished: (callback) ->
    @_emitter.on CHALLENGE_FINISHED, callback
    @

  onSolutionFeedback: (callback) ->
    @_emitter.on SOLUTION_RESPONSE, (response) =>
      callback(@_transformSolutionResponse(response))
    @

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

  # ### Wrapped ActionCable events ###

  onSubscriptionInitialized: (callback) ->
    @_emitter.on INITIALIZED, callback
    @

  onConnected: (callback) ->
    @_emitter.on CONNECTED, callback
    @

  onRejected: (callback) ->
    @_emitter.on REJECTED, callback
    @

  onDisconnected: (callback) ->
    @_emitter.on DISCONNECTED, callback
    @

  ### End of ActionCable events ###
