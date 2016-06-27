module.exports =
  class ChallengeSolvedView

    constructor: ->
      @element = document.createElement 'div'
      @element.classList.add 'challenge-solved-view'
      @element.textContent = "CHALLENGE SOLVED!"

    destroy: ->
      @element.remove()

    getElement: ->
      @element
