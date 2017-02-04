{MessagePanelView, LineMessageView, PlainMessageView} = require 'atom-message-panel'

plainTextToHtml = (text) ->
  text
    .replace /&/, '&amp'
    .replace /</, '&lt'
    .replace />/, '&gt'
    .replace /"/, '&quot'
    .replace /'/, '&apos'

module.exports =
  class ChallengeDescriptionView

    constructor: (@name, @description) ->
      title = @createTitle @name
      htmlEncodedDescription = plainTextToHtml @description

      @messages = new MessagePanelView
        title: title
        rawTitle: true
        closeMethod: 'hide'
      @messages.add new PlainMessageView
        message: "<pre>#{htmlEncodedDescription}</pre>"
        raw: true
        className: 'challenge-description'

    createTitle: (name) ->
      titleRoot = document.createElement 'div'
      titleRoot.classList.add 'challenge-title'

      currentChallengeText = document.createTextNode 'Current challenge: '
      titleRoot.appendChild currentChallengeText

      nameInBold = document.createElement 'b'
      nameInBold.textContent = name
      titleRoot.appendChild nameInBold

      titleRoot

    attach: ->
      @messages.attach()

    detach: ->
      @messages.detach()

    destroy: ->
      @detach()
