module.exports =
  class ChallengeSolvedView

    constructor: ->
      @element = document.createElement 'div'
      @element.classList.add 'volts'
      @element.style.width = '100%'
      @element.style.height = '104px'
      @element.style.backgroundImage = 'url(https://s3.amazonaws.com/coding.challenge/images/scale.png)'
      @element.style.backgroundPosition = '0px 30px'
      @element.style.backgroundRepeat = 'repeat-x'
      @element.style.backgroundSize = '104px 104px'
      @element.style.transition = 'background 350ms ease-in-out';
      @element.style.position = 'relative'

      @positioner = document.createElement 'div'
      @positioner.classList.add 'positioner'
      @positioner.style.width = '100%'
      @positioner.style.height = '2px'
      @positioner.style.background = '#3dff00'
      @positioner.style.position = 'absolute'
      @positioner.style.top = 'auto'
      @positioner.style.bottom = '0px'

      @element.appendChild(@positioner)

    destroy: ->
      @element.remove()

    getElement: ->
      @element
