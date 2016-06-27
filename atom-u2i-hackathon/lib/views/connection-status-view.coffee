module.exports =
  class ConnectionStatusView
    CONNECTED_DESCRIPTION = "Connected to the server as:"
    DISCONNECTED_DESCRIPTION =
      "Disconnected from the server. Please wait for reconnection or make sure the configuration is valid."
    INVALID_TOKEN_DESCRIPTION = "Connection to the server rejected. Make sure your team token is valid!"

    constructor: ->
      @element = document.createElement 'div'
      @element.classList.add 'connection-status-view'

      @disconnectedElement = document.createElement 'div'
      @disconnectedElement.classList.add 'disconnected'
      @disconnectedElement.textContent = DISCONNECTED_DESCRIPTION
      @element.appendChild @disconnectedElement

      @connectedElement = document.createElement 'div'
      @connectedElement.classList.add 'connected'
      @element.appendChild @connectedElement

      connectedDescription = document.createElement 'span'
      connectedDescription.textContent = CONNECTED_DESCRIPTION
      @connectedElement.appendChild connectedDescription

      @teamNameSpan = document.createElement 'span'
      @teamNameSpan.classList.add 'team-name'
      @connectedElement.appendChild @teamNameSpan

      @invalidTokenElement = document.createElement 'div'
      @invalidTokenElement.classList.add 'invalid-token'
      @invalidTokenElement.textContent = INVALID_TOKEN_DESCRIPTION
      @element.appendChild @invalidTokenElement

      @setDisconnected()

    setDisconnected: ->
      @showOnly @disconnectedElement

    showOnly: (visibleElement) ->
      Array.from(@element.childNodes).forEach (element) ->
        element.hidden = (element != visibleElement)

    setConnected: ->
      @showOnly @connectedElement

    setInvalidToken: ->
      @showOnly @invalidTokenElement

    setTeamName: (teamName) ->
      @teamNameSpan.textContent = teamName

    destroy: ->
      @element.remove()

    getElement: ->
      @element
