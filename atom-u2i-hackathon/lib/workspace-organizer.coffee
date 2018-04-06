fs = require 'fs'
mkdirp = require 'mkdirp'
moment = require 'moment'
path = require 'path'


{File} = require 'atom'
executeTasks = require './task-executor'

ChallengeDescriptionView = require './views/challenge-description-view'
LanguageChoiceView = require './views/language-choice-view'
ChallengeSolvedView = require './views/challenge-solved-view'
TestingView = require './views/testing-view'

module.exports =
class WorkspaceOrganizer

  hiddenChallenge = null
  hiddenTeam = null
  @validationMode = false
  @validatedSolution = null
  validationFileName = 'validation'

  constructor: (@solutionFolder, @snippetProvider, @validationModeView) ->
    @closeEditors()
    @_ensureSolutionFolderExists()
    @_createLanguageChoicePanel()
    @_createChallengeSolvedPanel()
    @_createValidationModePanel(@validationModeView)

  _ensureSolutionFolderExists: ->
    mkdirp.sync @solutionFolder

  _createLanguageChoicePanel: ->
    @_languageChoiceView = new LanguageChoiceView
    @_languageChoicePanel = atom.workspace.addTopPanel
      item: @_languageChoiceView.getElement(),
      visible: true

    changeLang = @_languageChoiceView.getButton()
    changeLang.addEventListener "click", =>
      @reloadLang(@solutionFolder, @snippetProvider)

  _createChallengeSolvedPanel: ->
    challengeSolvedView = new ChallengeSolvedView
    @_challengeSolvedPanel = atom.workspace.addTopPanel
      item: challengeSolvedView.getElement()
      visible: false

  _createValidationModePanel: (validationModeView) ->
    @_validationModePanel = atom.workspace.addTopPanel
      item: validationModeView.getElement()
      visible: false

  organizeWorkspaceOnChallengeStart: (challenge, teamId) ->
    # @hideLanguageChoice()
    hiddenChallenge = challenge
    hiddenTeam = teamId
    @closeEditors()
    @showChallengeDescription challenge
    @openEditorForChallenge challenge, teamId
   
  hideLanguageChoice: ->
    @_languageChoicePanel.hide()

  showLanguageChoice: ->
    @_languageChoicePanel.show()

  hideChallengeSolved: ->
    @_challengeSolvedPanel.hide()

  showChallengeSolved: ->
    @_challengeSolvedPanel.show()

  hideValidationMode: ->
    @_validationModePanel.hide()

  showValidationMode: ->
    @_validationModePanel.show()
  
  reloadLang: (@solutionFolder, @snippetProvider) ->
    @_ensureSolutionFolderExists()
    @closeEditors()
    # @showChallengeDescription hiddenChallenge
    @openEditorForChallenge hiddenChallenge, hiddenTeam

  closeEditors: ->
    atom.workspace.getTextEditors().forEach (editor) ->
      try
        editor.save()
      catch error
        console.warn('Nothing to save')
      editor.destroy()

  showChallengeDescription: (challenge) ->
    @_removeChallengeDescription()
    @_challengeDescriptionView = new ChallengeDescriptionView challenge.name, challenge.description
    @_challengeDescriptionView.attach()

  _removeChallengeDescription: ->
    @_challengeDescriptionView?.destroy()

  openEditorForChallenge: (challenge, teamId) ->
    existingFileName = @_findExistingFileName challenge, teamId
    if existingFileName
      @_openExistingFile existingFileName
    else
      @_openNewFile challenge, teamId

  getCurrentSolution: ->
    atom.workspace.getActiveTextEditor().getText()

  _putValidatedSolution: (solution) ->
    fileName = "#{validationFileName}.#{solution.language}"
    filePath = path.join @solutionFolder, fileName
    atom.workspace.open(filePath).then (editor) ->
      editor.setText solution.code
      editor.save()

  closeValidationWindow: () ->
    atom.workspace.getTextEditors().forEach (editor) ->
      if (editor?.buffer?.file?.path.indexOf(validationFileName) != -1)
        editor.destroy()

  chosenLanguageExtension: ->
    @_languageChoiceView.getChosenLanguageExtension()

  _findExistingFileName: (challenge, teamId) ->
    fileExtension = @_languageChoiceView.getChosenLanguageExtension()
    challengeId = challenge?.id
    namePattern = new RegExp "^\\d{8}-\\d{6}-#{challengeId}-#{teamId}.#{fileExtension}$"
    fileNames = fs.readdirSync @solutionFolder
    fileNames.find (name) -> namePattern.test name

  _openExistingFile: (fileName) ->
    filePath = path.join @solutionFolder, fileName
    atom.workspace.open(filePath).then (e) ->
      e.save()

  _openNewFile: (challenge, teamId) ->
    fileName = @_createFileName challenge, teamId
    filePath = path.join @solutionFolder, fileName
    fileExtension = @_languageChoiceView.getChosenLanguageExtension()
    @snippetProvider.provide(fileExtension).then (snippet) ->
      atom.workspace.open(filePath).then (editor) ->
        editor.setText snippet
        editor.save()

  _createFileName: (challenge, teamId) ->
    fileExtension = @_languageChoiceView.getChosenLanguageExtension()
    formattedDate = moment(challenge.createdAt).format 'YYYYMMDD-HHmmss'
    "#{formattedDate}-#{challenge.id}-#{teamId}.#{fileExtension}"

  organizeWorkspaceOnChallengeEnd: ->
    @_languageChoicePanel.show()
    hiddenChallenge = null
    hiddenTeam = null
    # @_removeChallengeDescription()
    atom.reload()

  switchToValidationMode: (solution) ->
    @validationMode = true
    @validatedSolution = solution

    @closeValidationWindow()
    @_challengeSolvedPanel.hide()
    @hideLanguageChoice()
    @showValidationMode()

    @_putValidatedSolution(solution)

  switchToNormalMode: ->
    @validationMode = false
    @validatedSolution = null

    @hideValidationMode()
    @closeValidationWindow()
    @showLanguageChoice()

  createTestingView: (runtime) ->
    testingView = new TestingView(runtime)
    @_testingViewPanel = atom.workspace.addLeftPanel
      item: testingView.getElement(),
      visible: true

  destroy: ->
    @_testingViewPanel?.destroy()
    @_languageChoicePanel?.destroy()
    @_challengeDescriptionView?.destroy()
    @_validationModePanel?.destroy()
    @_challengeSolvedPanel?.destroy()
