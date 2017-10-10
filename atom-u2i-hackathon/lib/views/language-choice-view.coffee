{exec} = require 'child_process'

VERSION_PATTERN = /\d+\.\d+\.\d+\S*/
VERSION_UNKNOWN = 'version unknown'

module.exports =
class LanguageChoiceView
  constructor: ->
    @languages = atom.config.get('u2i-hackathon.languages')

    @element = document.createElement 'div'
    @element.classList.add 'language-choice-view'

    description = document.createElement 'span'
    description.classList.add 'top-header'
    description.textContent = 'Pick a language for this challenge:'

    @changeLanguage = document.createElement 'button'
    @changeLanguage.classList.add 'change-language'
    @changeLanguage.innerText = 'Change Language'
    

    @element.appendChild description

    @comboBox = null
    @createComboBox()
    
    @element.appendChild @changeLanguage

  createComboBox: ->
    span = document.createElement 'span'
    span.setAttribute 'id', 'language-choice-box'

    @comboBox = document.createElement 'select'
    @languages.forEach ({extension, name, printVersionCommand}) =>
      option = document.createElement 'option'
      option.setAttribute 'value', extension
      option.label = "#{name} (#{VERSION_UNKNOWN})"
      @resolveVersion(printVersionCommand).then (version) ->
        option.label = "#{name} (#{version})"
      @comboBox.appendChild option

    span.appendChild @comboBox
    @element.appendChild span

  resolveVersion: (printVersionCommand) ->
    new Promise (resolve, reject) =>
      exec printVersionCommand, {timeout: 5000}, (err, stdout, stderr) =>
        if err
          resolve VERSION_UNKNOWN
        else
          result = stdout || stderr
          versionNumber = VERSION_PATTERN.exec(result)?[0]
          resolve(versionNumber || VERSION_UNKNOWN)

  getChosenLanguageExtension: ->
    @comboBox.value

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  getButton: ->
    @changeLanguage
