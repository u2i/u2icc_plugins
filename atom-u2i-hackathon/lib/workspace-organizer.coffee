fs = require 'fs'
mkdirp = require 'mkdirp'
moment = require 'moment'
path = require 'path'


{File} = require 'atom'
executeTasks = require './task-executor'

ChallengeDescriptionView = require './views/challenge-description-view'
LanguageChoiceView = require './views/language-choice-view'
TestingView = require './views/testing-view'

module.exports =
class WorkspaceOrganizer

  hiddenChallenge = null
  hiddenTeam = null

  constructor: (@solutionFolder, @snippetProvider) ->
    @_ensureSolutionFolderExists()
    @_createLanguageChoicePanel()

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
    
  organizeWorkspaceOnChallengeStart: (challenge, teamId) ->
    # @hideLanguageChoice()
    hiddenChallenge = challenge
    hiddenTeam = teamId
    @closeEditors()
    @showChallengeDescription challenge
    @openEditorForChallenge challenge, teamId
   
  hideLanguageChoice: ->
    @_languageChoicePanel.hide()
  
  reloadLang: (@solutionFolder, @snippetProvider) ->
    @_ensureSolutionFolderExists()
    @closeEditors()
    # @showChallengeDescription hiddenChallenge
    @openEditorForChallenge hiddenChallenge, hiddenTeam

  closeEditors: ->
    atom.workspace.getTextEditors().forEach (editor) ->
      editor.save()
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

  _findExistingFileName: (challenge, teamId) ->
    fileExtension = @_languageChoiceView.getChosenLanguageExtension()
    namePattern = new RegExp "^\\d{8}-\\d{6}-#{challenge.id}-#{teamId}.#{fileExtension}\\..+$"
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
    # @_languageChoicePanel.show()
    hiddenChallenge = null
    hiddenTeam = null
    # @_removeChallengeDescription()
    atom.reload()

  createTestingView: (runtime) ->
    testingView = new TestingView(runtime)
    @_testingViewPanel = atom.workspace.addLeftPanel
      item: testingView.getElement(),
      visible: true

  destroy: ->
    @_testingViewPanel?.destroy()
    @_languageChoicePanel?.destroy()
    @_challengeDescriptionView?.destroy()
