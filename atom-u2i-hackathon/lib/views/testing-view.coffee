executeTasks = require '../task-executor'
{File} = require 'atom'

inputRowHtml = '
<textarea rows="1" placeholder="Your input here..." class="testing-view-input native-key-bindings"></textarea>
<button type="button" class="btn btn-xs testing-view-remove-button octicon(remove-close)"></button>'

testingViewInnerHtml = '
<div class="testing-view-header">Test your code!</div>
<div class="testing-view-body">
  <button type="button" class="btn" id="testing-view-add-button">Add input</button>
  <div id="testing-view-inputs"></div>
  <button type="button" class="btn btn-primary" id="testing-view-run-button">Run!</button>
  <div class="testing-view-header">Outputs:</div>
  <div id="testing-view-outputs"></div>
  <div class="testing-view-header">Errors:</div>
  <div id="testing-view-errors"></div>
</div>'

module.exports =
class TestingView
  constructor: (@runtime) ->
    @element = document.createElement 'div'
    @element.classList.add 'testing-view'
    @element.innerHTML = testingViewInnerHtml

    @addInput()

    @element.querySelector('#testing-view-add-button').addEventListener "click", =>
      @addInput()
    @element.querySelector('#testing-view-run-button').addEventListener "click", =>
      @run()

  addInput: ->
    inputRow = document.createElement 'div'
    inputRow.classList.add 'testing-view-input-row'
    inputRow.innerHTML = inputRowHtml

    inputRow.querySelector('.testing-view-remove-button').addEventListener 'click', (event) =>
      event.target.parentNode.remove()

    textarea = inputRow.querySelector '.testing-view-input'
    textarea.addEventListener 'keydown', (event) =>
      numberOfRows = textarea.value.split("\n").length
      textarea.setAttribute 'rows', numberOfRows

    @element.querySelector('#testing-view-inputs').appendChild inputRow
    textarea.focus()

  run: ->
    @clearOutputsAndErrors()
    @removeEmptyInputs()
    @runWithInputs()
    @ensureAtLeastOneInput()

  clearOutputsAndErrors: ->
    ['#testing-view-outputs', '#testing-view-errors'].forEach (id) =>
      div = @element.querySelector id
      while div.lastChild
        div.removeChild(div.lastChild)

  removeEmptyInputs: ->
    @getTextAreasArray()
      .filter((textarea) -> textarea.value == '')
      .forEach((textarea) -> textarea.parentNode.remove())

  getTextAreasArray: ->
    textareas = @element.querySelectorAll '.testing-view-input'
    Array.from textareas

  runWithInputs: ->
    textareas = @getTextAreasArray()
    if textareas.length > 0
      inputs = (_.value for _ in textareas)
      outputsCallback = (outputs) => @addOutputs outputs
      errorCallback = (error) => @addError error
      executeTasks @runtime, inputs, outputsCallback, errorCallback

  addOutputs: (outputs) ->
    outputsElement = @element.querySelector('#testing-view-outputs')
    outputs.forEach (output) =>
      outputDiv = document.createElement 'pre'
      outputDiv.classList.add 'testing-view-output'
      outputDiv.textContent = output.trim()
      outputsElement.appendChild outputDiv

  addError: (error) ->
    errorDiv = document.createElement 'pre'
    errorDiv.classList.add 'testing-view-error'
    errorDiv.textContent = error
    @element.querySelector('#testing-view-errors').appendChild errorDiv

  ensureAtLeastOneInput: ->
    textareas = @getTextAreasArray()
    if textareas.length == 0
      @addInput()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
