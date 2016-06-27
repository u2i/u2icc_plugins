U2iHackathon = require '../lib/u2i-hackathon'

LANGUAGES_CONFIG = [
  {
    name: 'Java'
    extension: 'java'
    execDirectory: '/opt/java/bin'
    printVersionCommand: 'java -version'
  }
  {
    name: 'Scala'
    extension: 'scala'
    execDirectory: '/usr/local/Cellar/scala/2.11.2/bin'
    printVersionCommand: 'scala -version'
  }
]

describe "U2iHackathon", ->
  mockChallenge =
    plugins: []
    name: ''
    description: ''
    id: '3'

  [hackathonPackage] = []

  it "disables the 'autocomplete-plus' package when a challenge starts", ->
    waitsForPromise ->
      atom.packages.activatePackage('autocomplete-plus')

    waitsForPromise ->
      expect(atom.packages.isPackageActive('autocomplete-plus')).toEqual true
      expect(atom.packages.isPackageDisabled('autocomplete-plus')).toEqual false
      atom.packages.activatePackage('u2i-hackathon').then (pakage) ->
        hackathonPackage = pakage

    runs ->
      hackathonPackage.mainModule.startChallenge mockChallenge
      expect(atom.packages.isPackageDisabled('autocomplete-plus')).toEqual true

  it "adds exec directories for languages specified in config to path", ->
    [expectedNewPath] = []

    runs ->
      atom.config.set('u2i-hackathon.languages', LANGUAGES_CONFIG)
      execDirectoriesInConfig = (_.execDirectory for _ in LANGUAGES_CONFIG)
      colonSeparatedExecDirectories = execDirectoriesInConfig.join ':'
      expectedNewPath = "#{colonSeparatedExecDirectories}:#{process.env.PATH}"

    waitsForPromise ->
      atom.packages.activatePackage('u2i-hackathon')

    runs ->
      expect(process.env.PATH).toEqual expectedNewPath

  it "notifies the user if the package config is invalid", ->
    expectedErrorMessage = /The config for package "u2i-hackathon" is invalid\. Check your "config\.cson" file\. Errors:/

    runs ->
      invalidConfig = LANGUAGES_CONFIG.concat [{}]
      atom.config.set('u2i-hackathon.languages', invalidConfig)
      spyOn(console, 'error')
      spyOn(atom.notifications, 'addFatalError')

    waitsForPromise ->
      atom.packages.activatePackage('u2i-hackathon')

    runs ->
      for spy in [console.error, atom.notifications.addFatalError]
        expect(spy).toHaveBeenCalled()
        expect(spy.calls[0].args[0]).toMatch expectedErrorMessage
