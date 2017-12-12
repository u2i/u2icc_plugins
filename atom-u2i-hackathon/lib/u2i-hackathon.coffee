ActionCableSubscription = require './action-cable-subscription'
ChallengesService = require './challenges-service'
ChallengeSolvedView = require './views/challenge-solved-view'
ConnectionStatusView = require './views/connection-status-view'
PackageActivator = require './package-activator'
executeTasks = require './task-executor'
SnippetProvider = require './snippet-provider'
WorkspaceOrganizer = require './workspace-organizer'

{CompositeDisposable} = require 'atom'
{validate} = require 'jsonschema'

CANNOT_CONNECT_MSG = "Cannot connect to the server to check your solution. " +
                     "Please wait for reconnection and try again."
CONFIG_INVALID_MSG = 'The config for package "u2i-hackathon" is invalid. ' +
                     'Check your "config.cson" file. Errors:'

module.exports =
  config:
    token:
      type: 'string'
      default: ''
    cableServerUrl:
      type: 'string'
      default: 'ws://localhost:3000/cable'
    solutionFolder:
      type: 'string'
      default: '/tmp/u2icc-solutions'
    commandOverwrites:
      type: 'object'
      default: {}
    languages:
      type: 'array'
      default: [
        {
          name: 'JavaScript (node.js)'
          extension: 'js'
          execDirectory: '/usr/local/bin'
          printVersionCommand: 'node --version'
        }
      ]
      items:
        type: 'object'
        properties:
          name:
            type: 'string'
          extension:
            type: 'string'
          execDirectory:
            type: 'string'
          printVersionCommand:
            type: 'string'
        required: ['name', 'extension', 'execDirectory', 'printVersionCommand']

  challengesService: null
  packageActivator: null
  notificationManager: null
  runtime: null
  workspaceOrganizer: null
  teamIdPromise: null
  challengeSolvedPanel: null
  currentChallengeSolved: false

  activate: (state) ->
    console.log("Activating u2i-hackathon!!!")

    @packageActivator = new PackageActivator
    @notificationManager = atom.notifications
    snippetProvider = new SnippetProvider

    @validateConfig()
    @prependExecDirectoriesToPath()

    teamToken = (atom.config.get 'u2i-hackathon.token')
    cableServerUrl = (atom.config.get 'u2i-hackathon.cableServerUrl')
    solutionFolder = (atom.config.get 'u2i-hackathon.solutionFolder')

    console.log("Connecting to: " +  cableServerUrl)
    console.log("Solution folder: " + solutionFolder)

    @actionCableSubscription = new ActionCableSubscription cableServerUrl, teamToken
    @challengesService = new ChallengesService @actionCableSubscription

    connectionStatusView = new ConnectionStatusView
    # move everything to connectionStatusView?
    @actionCableSubscription.onConnected ->
      connectionStatusView.setConnected()
    @actionCableSubscription.onDisconnected ->
      connectionStatusView.setDisconnected()
    @actionCableSubscription.onRejected ->
      connectionStatusView.setInvalidToken()
    @challengesService.onTeamDetails (teamDetails) ->
      connectionStatusView.setTeamName teamDetails.name
    atom.workspace.addTopPanel
      item: connectionStatusView.getElement(),
      visible: true

    @workspaceOrganizer = new WorkspaceOrganizer solutionFolder, snippetProvider

    @teamIdPromise = new Promise (resolve, reject) =>
      @challengesService.onTeamDetails (teamDetails) ->
        resolve teamDetails.id

    @challengesService.onChallengeStarted (challenge) =>
      @startChallenge challenge
    @challengesService.onChallengeFinished =>
      @stopChallenge()
    @challengesService.onSolutionFeedback (feedback) =>
      @onSolutionFeedback feedback

    @actionCableSubscription.subscribe()

    @packageActivator.activatePackage('script')

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'u2i-hackathon:run': => @runChallenge()
    

    challengeSolvedView = new ChallengeSolvedView
    @challengeSolvedPanel = atom.workspace.addTopPanel
      item: challengeSolvedView.getElement()
      visible: false

  validateConfig: ->
    packageConfig = atom.config.get('u2i-hackathon')
    packageConfigSchema = atom.config.getSchema().properties['u2i-hackathon']
    validationResult = validate packageConfig, packageConfigSchema
    window.validationResult = validationResult
    unless validationResult.valid
      errorDescriptions = validationResult.errors.map (_) -> _.toString()
      errorMessage = [CONFIG_INVALID_MSG].concat(errorDescriptions).join "\n"
      console.error errorMessage
      @notificationManager.addFatalError errorMessage

  prependExecDirectoriesToPath: ->
    languagesConfig = atom.config.get('u2i-hackathon.languages')
    execDirectories = (_.execDirectory for _ in languagesConfig)
    colonSeparatedExecDirectories = execDirectories.join ':'
    process.env.PATH = "#{colonSeparatedExecDirectories}:#{process.env.PATH}"

  startChallenge: (challenge) ->
    try
      @activatePackages(challenge.plugins)
      @notificationManager.addInfo("Challenge started: " + challenge.name)
      @teamIdPromise.then (teamId) =>
        @workspaceOrganizer.organizeWorkspaceOnChallengeStart challenge, teamId
      @challengeSolvedPanel.hide()
      @currentChallengeSolved = false
      @disableAutocomplete()
    catch error
      @notificationManager.addError(error.message)

  activatePackages: (plugins) ->
    result = @packageActivator.activatePackages(plugins)
    if result.failedPackages.length > 0
      @notificationManager.addWarning "Failed to activate plugins: #{JSON.stringify result.failedPackages}"

  disableAutocomplete: ->
    atom.packages.disablePackage 'autocomplete-plus'

  stopChallenge: ->
    # @keystrokeCounter.stop()
    @notificationManager.addWarning "Challenge finished!"
    @challengeSolvedPanel.hide()
    @currentChallengeSolved = false
    @packageActivator.deactivatePackages()
    @workspaceOrganizer.organizeWorkspaceOnChallengeEnd()

  onSolutionFeedback: (solutionFeedback) ->
    if solutionFeedback.success
      @notificationManager.addInfo(solutionFeedback.message)
      @challengeSolvedPanel.show()
      @currentChallengeSolved = true
    else
      @notificationManager.addError(solutionFeedback.message)

  runChallenge: ->
    if @currentChallengeSolved
      @notificationManager.addInfo "You've already submitted a correct solution!"
    else
      try
        inputs = @challengesService.getCurrentChallenge().inputs
        outputsCallback = (outputs) => @onOutputs outputs
        errorCallback = (error) => @notificationManager.addError error
        @notificationManager.addInfo("Checking your solution!!!")
        executeTasks @runtime, inputs, outputsCallback, errorCallback
      catch error
        @notificationManager.addError(
          "Error while checking your solution:\n" + error.message)

  onOutputs: (outputs) ->
    code = @workspaceOrganizer.getCurrentSolution()
    chosenLanguage = @workspaceOrganizer.chosenLanguageExtension()
    requestSuccessful = @challengesService.checkSolution outputs, code, chosenLanguage
    unless requestSuccessful
      @notificationManager.addWarning CANNOT_CONNECT_MSG

  deactivate: ->
    @actionCableSubscription?.destroy()
    @challengesService?.destroy()
    @subscriptions?.dispose()
    @runtime?.destroy()
    @counter?.destroy()
    @workspaceOrganizer.destroy()
    @challengeSolvedPanel?.destroy()

  consumeBlankRuntime: (runtime) ->
    console.log("CONSUME BLANK");
    @runtime = runtime
    @workspaceOrganizer.createTestingView runtime

  consumeKeystrokeCounter: (keystrokeCounter) ->
    @keystrokeCounter = keystrokeCounter

  serialize: ->
