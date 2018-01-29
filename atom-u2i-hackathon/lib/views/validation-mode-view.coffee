module.exports =
  class ValidationModeView

    constructor: ->
      @element = document.createElement 'div'
      @element.classList.add 'validation-mode-view'

      messageSpan = document.createElement 'span'
      messageSpan.setAttribute 'id', 'validation-mode-message'
      messageSpan.textContent = 'VALIDATION MODE'
      @element.appendChild messageSpan

      @exitButton = document.createElement 'button'
      @exitButton.setAttribute 'id', 'exit-button'
      @exitButton.innerText = 'EXIT'
      @element.appendChild @exitButton

    destroy: ->
      @element.remove()

    getElement: ->
      @element

    getButton: ->
      @exitButton
