# SERVICE_URL = 'http://blog.u2i.com:3031'
ChallengesService = require './challenges-service'
PackageActivator = require './package-activator'
executeTasks = require './task-executor'
ChallengeDescriptionView = require './challenge-description-view'
TestingView = require './testing-view'
LanguageChoiceView = require './language-choice-view'
WorkspaceOrganizer = require './workspace-organizer'

{CompositeDisposable} = require 'atom'

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

  challengesService: null
  packageActivator: null
  notificationManager: null
  runtime: null
  testingViewPanel: null
  languageChoicePanel: null
  languageChoiceView: null
  challengeDescriptionView: null
  workspaceOrganizer: null

  activate: (state) ->
    console.log("Activating u2i-hackathon!!!")
    teamToken = (atom.config.get 'u2i-hackathon.token')
    cableServerUrl = (atom.config.get 'u2i-hackathon.cableServerUrl')
    solutionFolder = (atom.config.get 'u2i-hackathon.solutionFolder')
    @challengesService = new ChallengesService(cableServerUrl, teamToken)
    @packageActivator = new PackageActivator
    @notificationManager = atom.notifications

    @showLanguageChoiceView()
    @workspaceOrganizer = new WorkspaceOrganizer
      languageChoicePanel: @languageChoicePanel
      languageChoiceView: @languageChoiceView
      solutionFolder: solutionFolder
      teamToken: teamToken

    @challengesService
      .onChallengeStarted( (challenge) =>
        @startChallenge(challenge)
      ).onChallengeFinished( =>
        @stopChallenge()
      ).onSolutionFeedback( (feedback) =>
        @onSolutionFeedback(feedback)
      ).onConnected( =>
        @notificationManager.addInfo("Connected to the Hackathon server")
      ).onDisconnected( =>
        @notificationManager.addWarning("Disconnected from the Hackathon server")
      ).onRejected( =>
        @notificationManager.addError("Connection to the Hackathon server rejected. Make sure your team token is valid.")
      )

    @packageActivator.activatePackage('script')

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'u2i-hackathon:run': => @runChallenge()

  startChallenge: (challenge) ->
    try
      @packageActivator.activatePackages(challenge.plugins)
      @notificationManager.addInfo("Challenge started: " + challenge.name)
      @showDescription(challenge)
      @workspaceOrganizer.organizeWorkspaceOnChallengeStart(challenge)

    catch error
      @notificationManager.addError(error.message)

  showDescription: (challenge) ->
    @hideDescription()
    @challengeDescriptionView = new ChallengeDescriptionView(challenge.name, challenge.description)
    @challengeDescriptionView.attach()

  hideDescription: ->
    @challengeDescriptionView?.destroy()

  stopChallenge: ->
    # @keystrokeCounter.stop()
    @notificationManager.addWarning "Challenge finished!"
    @packageActivator.deactivatePackages()
    @hideDescription()
    @workspaceOrganizer.organizeWorkspaceOnChallengeEnd()

  onSolutionFeedback: (solutionFeedback) ->
    if solutionFeedback.success
      @notificationManager.addInfo(solutionFeedback.message)
    else
      @notificationManager.addError(solutionFeedback.message)

  runChallenge: ->
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
    @challengesService.checkSolution outputs

  showLanguageChoiceView: ->
    @languageChoiceView = new LanguageChoiceView
    @languageChoicePanel = atom.workspace.addTopPanel
      item: @languageChoiceView.getElement(),
      visible: true

  deactivate: ->
    @challengesService?.destroy()
    @subscriptions?.dispose()
    @runtime?.destroy()
    @counter?.destroy()
    @testingViewPanel?.destroy()
    @languageChoiceView?.destroy()
    @languageChoicePanel?.destroy()

  consumeBlankRuntime: (runtime) ->
    @runtime = runtime
    @showTestingView(runtime)

  showTestingView: (runtime) ->
    testingView = new TestingView(runtime)
    @testingViewPanel = atom.workspace.addLeftPanel
      item: testingView.getElement(),
      visible: true

  consumeKeystrokeCounter: (keystrokeCounter) ->
    @keystrokeCounter = keystrokeCounter

  serialize: ->
