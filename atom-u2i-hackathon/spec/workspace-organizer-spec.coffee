fs = require 'fs'
moment = require 'moment'
path = require 'path'
temp = require('temp').track()
using = require 'jasmine-data-provider'

ChallengeDescriptionView = require './../lib/views/challenge-description-view'
LanguageChoiceView = require './../lib/views/language-choice-view'
TestingView = require './../lib/views/testing-view'
WorkspaceOrganizer = require './../lib/workspace-organizer'

describe 'WorkspaceOrganizer', ->
  solutionFolder = temp.mkdirSync()
  teamId = '23870dfabc384982347'
  mockChallenge =
    id: '889fabc8942aba030'
    name: 'Challenge name'
    description: 'Challenge description'

  [workspaceOrganizer, workspaceElement] = []

  emptyFolder = (folderPath) ->
    fs.readdirSync(folderPath).forEach (name) ->
      filePath = path.join(folderPath, name)
      if fs.statSync(filePath).isFile()
        fs.unlink filePath
      else
        emptyFolder filePath
        fs.rmdirSync filePath

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    atom.config.set('u2i-hackathon.languages', [])

  describe 'constructor', ->
    describe 'when the solution folder exists and is writable', ->
      beforeEach ->
        workspaceOrganizer = new WorkspaceOrganizer solutionFolder

      it "assigns the 'solutionFolder' field", ->
        expect(workspaceOrganizer.solutionFolder).toEqual solutionFolder

      it "assigns a new LanguageChoiceView as '_languageChoiceView'", ->
        expect(workspaceOrganizer._languageChoiceView.constructor.name).toEqual(
          LanguageChoiceView.name)

      it "adds a top panel for language choice and assigns it as '_languageChoicePanel'", ->
        expect(workspaceOrganizer._languageChoicePanel).toBeDefined()
        expect(workspaceOrganizer._languageChoicePanel).toBe(
          atom.workspace.getTopPanels()[0])

      it "makes the language choice panel visible", ->
        languageChoiceElement = workspaceElement.querySelector '.language-choice-view'
        expect(languageChoiceElement).toExist()

        jasmine.attachToDOM workspaceElement
        expect(languageChoiceElement).toBeVisible()

    describe 'when the solution folder is missing but can be created', ->
      it "creates the folder", ->
        missingFolderPath = path.join solutionFolder, 'missing/a/b/c'
        expect(-> fs.accessSync missingFolderPath, fs.W_OK).toThrow()
        new WorkspaceOrganizer missingFolderPath
        expect(-> fs.accessSync missingFolderPath, fs.W_OK).not.toThrow()

  describe 'organizeWorkspaceOnChallengeStart', ->
    [mockPromise, returnValue] = []

    beforeEach ->
      stubbedMethods = ['hideLanguageChoice', 'showChallengeDescription', 'closeEditors']
      stubbedMethods.forEach (methodName) ->
        spyOn(workspaceOrganizer, methodName)
      mockPromise = {a: 1}
      spyOn(workspaceOrganizer, 'openEditorForChallenge').andCallFake ->
        expect(workspaceOrganizer.closeEditors).toHaveBeenCalled()
        mockPromise

    beforeEach ->
      returnValue = workspaceOrganizer.organizeWorkspaceOnChallengeStart mockChallenge, teamId

    using ['hideLanguageChoice', 'closeEditors'], (methodName) ->
      it "calls '#{methodName}' once", ->
        expect(workspaceOrganizer[methodName].calls.length).toEqual 1

    it "calls ::showChallengeDescription", ->
      expect(workspaceOrganizer.showChallengeDescription).toHaveBeenCalledWith mockChallenge

    it "calls ::openEditorForChallenge", ->
      expect(workspaceOrganizer.openEditorForChallenge).toHaveBeenCalledWith mockChallenge, teamId

    it "returns the promise returned by 'openEditorForChallenge'", ->
      expect(returnValue).toEqual mockPromise

  describe 'hideLanguageChoice', ->
    it 'hides the language choice panel', ->
      new WorkspaceOrganizer(solutionFolder).hideLanguageChoice()

      languageChoiceElement = workspaceElement.querySelector '.language-choice-view'
      expect(languageChoiceElement).toExist()

      jasmine.attachToDOM workspaceElement
      expect(languageChoiceElement).not.toBeVisible()

  describe 'closeEditors', ->
    it "closes all the open editors", ->
      waitsForPromise ->
        editorPromises = [1..3].map -> atom.workspace.open()
        Promise.all editorPromises

      runs ->
        workspaceOrganizer.closeEditors()
        expect(atom.workspace.getTextEditors().length).toEqual 0

  describe 'showChallengeDescription', ->
    beforeEach ->
      spyOn(ChallengeDescriptionView.prototype, 'attach').andCallThrough()
      workspaceOrganizer = new WorkspaceOrganizer solutionFolder

    it "assigns a new challenge description view as '_challengeDescriptionView'", ->
      workspaceOrganizer.showChallengeDescription mockChallenge
      expect(workspaceOrganizer._challengeDescriptionView.constructor.name).toEqual(
        ChallengeDescriptionView.name)

    it "creates the challenge description view with a correct name and description", ->
      workspaceOrganizer.showChallengeDescription mockChallenge
      challengeDescriptionView = workspaceOrganizer._challengeDescriptionView
      expect(challengeDescriptionView.name).toEqual mockChallenge.name
      expect(challengeDescriptionView.description).toEqual mockChallenge.description

    it 'shows the new description view', ->
      workspaceOrganizer.showChallengeDescription mockChallenge
      expect(workspaceOrganizer._challengeDescriptionView.attach).toHaveBeenCalled()

    it "closes the old challenge description view", ->
      oldDescriptionView = jasmine.createSpyObj 'oldDescriptionView', ['destroy']
      workspaceOrganizer._challengeDescriptionView = oldDescriptionView

      workspaceOrganizer.showChallengeDescription mockChallenge
      expect(workspaceOrganizer.challengeDescriptionView).not.toBe oldDescriptionView
      expect(oldDescriptionView.destroy).toHaveBeenCalled()

  describe 'openEditorForChallenge', ->
    fileExtension = 'scala'
    snippet = 'this is a scala snippet'
    mockSnippetProvider =
      provide: (extension) ->

    beforeEach ->
      workspaceOrganizer = new WorkspaceOrganizer solutionFolder, mockSnippetProvider
      spyOn(workspaceOrganizer._languageChoiceView, 'getChosenLanguageExtension').
        andReturn fileExtension
      spyOn(mockSnippetProvider, 'provide').andReturn(Promise.resolve(snippet))

    it "opens an editor for the started challenge and returns a promise", ->
      waitsForPromise ->
        workspaceOrganizer.openEditorForChallenge mockChallenge, teamId

      runs ->
        actualEditors = atom.workspace.getTextEditors()
        expect(actualEditors.length).toEqual 1

    describe "creating a file for the started challenge", ->
      newFileNamePattern =
        new RegExp "^\\d{8}-\\d{6}-#{mockChallenge.id}-#{teamId}\\.#{fileExtension}$"
      existingFileContent = '(+ 1 2 3 4)'

      createSolutionFile = (name) ->
        filePath = path.join solutionFolder, name
        fs.appendFileSync filePath, existingFileContent

      verifyNewFileExistence = ->
        challengeEditor = atom.workspace.getTextEditors()[0]

        actualFileNames = fs.readdirSync solutionFolder
        matchingFileNames = actualFileNames.filter (name) -> newFileNamePattern.test name

        expect(matchingFileNames.length).toEqual 1
        expect(challengeEditor.getTitle()).toEqual matchingFileNames[0]
        expect(challengeEditor.isModified()).toEqual false

        verifyNameHasCorrectDate matchingFileNames[0]
        verifyNewFileContent matchingFileNames[0]

      verifyNameHasCorrectDate = (fileName) ->
        dateStringInFileName = fileName.slice 0, 15
        dateInFileName = moment dateStringInFileName, 'YYYYMMDD-HHmmss'
        timeDifference = Math.abs moment().diff(dateInFileName, 'second')
        expect(timeDifference).toBeLessThan 2

      verifyNewFileContent = (fileName) ->
        filePath = path.join solutionFolder, fileName
        newFileContent = fs.readFileSync(filePath).toString()
        expect(newFileContent).toEqual snippet

      beforeEach ->
        emptyFolder solutionFolder

      it "creates a file unless one already exists", ->
        waitsForPromise ->
          workspaceOrganizer.openEditorForChallenge mockChallenge, teamId

        runs ->
          expect(mockSnippetProvider.provide).toHaveBeenCalledWith fileExtension
          verifyNewFileExistence()

      it "creates a file if one exists for a different challenge", ->
        runs ->
          createSolutionFile "20150101-043145-differentChallengeId-#{teamId}.lisp"

        waitsForPromise ->
          workspaceOrganizer.openEditorForChallenge mockChallenge, teamId

        runs ->
          expect(mockSnippetProvider.provide).toHaveBeenCalledWith fileExtension
          verifyNewFileExistence()

      it "creates a file if one exists for a different team", ->
        runs ->
          createSolutionFile "20150101-043145-#{mockChallenge.id}-differentTeamId.lisp"

        waitsForPromise ->
          workspaceOrganizer.openEditorForChallenge mockChallenge, teamId

        runs ->
          expect(mockSnippetProvider.provide).toHaveBeenCalledWith fileExtension
          verifyNewFileExistence()

      it "does not create a file if a file for this team and challenge exists", ->
        existingFileName = "20150101-043145-#{mockChallenge.id}-#{teamId}.lisp"
        existingFilePath = path.join solutionFolder, existingFileName

        runs ->
          createSolutionFile existingFileName

        waitsForPromise ->
          workspaceOrganizer.openEditorForChallenge mockChallenge, teamId

        runs ->
          challengeEditor = atom.workspace.getTextEditors()[0]

          actualFileNames = fs.readdirSync solutionFolder
          matchingNewFileNames = actualFileNames.filter (name) -> newFileNamePattern.test name
          expect(matchingNewFileNames.length).toEqual 0

          actualPath = challengeEditor.getPath()
          expect(challengeEditor.isModified()).toEqual false
          expect(fs.realpathSync(actualPath)).toEqual fs.realpathSync(existingFilePath)

          expect(mockSnippetProvider.provide).not.toHaveBeenCalled()
          expect(challengeEditor.getText()).toEqual existingFileContent

  describe 'organizeWorkspaceOnChallengeEnd', ->
    beforeEach ->
      workspaceOrganizer = new WorkspaceOrganizer solutionFolder

    it 'shows the language choice panel', ->
      showSpy = spyOn(workspaceOrganizer._languageChoicePanel, 'show')
      workspaceOrganizer.organizeWorkspaceOnChallengeEnd()
      expect(showSpy).toHaveBeenCalled()

    it 'removes the challenge description if present', ->
      workspaceOrganizer._challengeDescriptionView = jasmine.createSpyObj 'challengeDescriptionView', ['destroy']
      workspaceOrganizer.organizeWorkspaceOnChallengeEnd()
      expect(workspaceOrganizer._challengeDescriptionView.destroy).toHaveBeenCalled()

    it 'does not remove the challenge description if not present', ->
      workspaceOrganizer._challengeDescriptionView = undefined
      expect(-> workspaceOrganizer.organizeWorkspaceOnChallengeEnd()).not.toThrow()

  describe 'createTestingView', ->
    beforeEach ->
      workspaceOrganizer = new WorkspaceOrganizer solutionFolder

    mockRuntime = {a: 1}

    it "adds a left panel for the testing view", ->
      testingViewElement = {b: 2}
      getElement = spyOn(TestingView.prototype, 'getElement').andCallFake () ->
        expect(this.runtime).toBe mockRuntime
        testingViewElement
      addLeftPanel = spyOn(atom.workspace, 'addLeftPanel')

      workspaceOrganizer.createTestingView mockRuntime
      expect(addLeftPanel).toHaveBeenCalledWith
        item: testingViewElement
        visible: true

    it "assigns the added panel as '_testingViewPanel'", ->
      mockPanel = {c: 3}
      spyOn(atom.workspace, 'addLeftPanel').andReturn mockPanel

      workspaceOrganizer.createTestingView mockRuntime
      expect(workspaceOrganizer._testingViewPanel).toBeDefined()
      expect(workspaceOrganizer._testingViewPanel).toBe mockPanel

  describe 'destroy', ->
    beforeEach ->
      workspaceOrganizer = new WorkspaceOrganizer solutionFolder

    using ['_testingViewPanel', '_languageChoicePanel', '_challengeDescriptionView'], (fieldName) ->
      it "destroys '#{fieldName}' if present", ->
        workspaceOrganizer[fieldName] = jasmine.createSpyObj fieldName, ['destroy']
        workspaceOrganizer.destroy()
        expect(workspaceOrganizer[fieldName].destroy).toHaveBeenCalled()

      it "does not destroy '#{fieldName}' if absent", ->
        workspaceOrganizer[fieldName] = undefined
        expect(-> workspaceOrganizer.destroy()).not.toThrow()
