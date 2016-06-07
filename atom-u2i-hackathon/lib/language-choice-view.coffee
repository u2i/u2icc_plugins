fileExtensionsWithLanguageNames = [
  ['rb', 'Ruby'],
  ['py', 'Python'],
  ['js', 'JavaScript']
]

module.exports =
class LanguageChoiceView
  constructor: ->
    @element = document.createElement 'div'
    @element.classList.add 'language-choice-view'

    description = document.createElement 'span'
    description.classList.add 'top-header'
    description.textContent = 'Pick a language for the next challenge:'
    @element.appendChild description

    @comboBox = null
    @createComboBox()

  createComboBox: ->
    div = document.createElement 'span'
    div.setAttribute 'id', 'language-choice-box'

    @comboBox = document.createElement 'select'
    fileExtensionsWithLanguageNames.forEach ([extension, name]) =>
      option = document.createElement 'option'
      option.setAttribute 'value', extension
      option.label = name
      @comboBox.appendChild option

    div.appendChild @comboBox
    @element.appendChild div

  getChosenLanguageExtension: ->
    @comboBox.value

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
