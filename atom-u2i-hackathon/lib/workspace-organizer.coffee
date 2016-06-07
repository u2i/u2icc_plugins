moment = require 'moment'

module.exports =
class WorkspaceOrganizer
  constructor: ({@languageChoicePanel, @languageChoiceView, @solutionFolder, @teamToken}) ->
    @solutionFolder += '/' unless @solutionFolder.endsWith('/')

  organizeWorkspaceOnChallengeStart: (challenge) ->
    @closeEditors()
    @openEditorForChosenLanguage(challenge.name)
    @hideLanguageChoice()

  closeEditors: ->
    atom.workspace.getTextEditors().forEach (editor) -> editor.destroy()

  openEditorForChosenLanguage: (challengeName) ->
    fileExtension = @languageChoiceView.getChosenLanguageExtension()
    formattedDate = moment().format('YYYYMMDD-HHmmss')
    formattedName = challengeName.replace(/\W+/g, '_').slice(0, 16)
    fileName = "#{formattedDate}-#{formattedName}-#{@teamToken}.#{fileExtension}"
    filePath = @solutionFolder + fileName
    atom.workspace.open(filePath)

  hideLanguageChoice: ->
    @languageChoicePanel.hide()

  organizeWorkspaceOnChallengeEnd: ->
    @languageChoicePanel.show()
