{CompositeDisposable} = require 'atom'

class TaskExecutor

  constructor: (@runtime, @inputs, @onOutputs, @onError) ->
    @outputs = []
    @finishedProcesses = 0
    @subscriptions = new CompositeDisposable
    @observeRuntime()
    @timer = null

  observeRuntime: ->
    @subscriptions.add @runtime.onDidWriteToStderr (ev) =>
      @onError("stderr: #{ev.message}")
    @subscriptions.add @runtime.onDidWriteToStdout (ev) =>
      @outputs.push ev.message.trim()
      @checkIfOutputsReady()
    @subscriptions.add @runtime.onDidNotRun (ev) =>
      @onError("Unable to run: #{ev.command}")
    @subscriptions.add @runtime.onDidNotSpecifyLanguage =>
      @onError("Language not specified")
    @subscriptions.add @runtime.onDidNotSupportLanguage (ev) =>
      @onError("Language not supported: #{ev.lang}")
    @subscriptions.add @runtime.onDidNotBuildArgs (ev) =>
      @onError("Unknown error: #{ev.error}")
    @subscriptions.add @runtime.onDidExit (ev) =>
      @onExit(ev.returnCode)

  checkIfOutputsReady: ->
    if @finishedProcesses == @outputs.length
      if @finishedProcesses == @inputs.length
        @cleanUp()
        @onOutputs @outputs
      else
        @executeNthInput @finishedProcesses

  cleanUp: ->
    clearTimeout @timer
    @subscriptions?.dispose()

  executeNthInput: (n) ->
    @runtime.execute "File Based", @inputs[n]

  onExit: (returnCode) ->
    if returnCode != 0
      @cleanUp()
      @onError "Your program exited with exit code #{returnCode}"
    else
      ++@finishedProcesses
      @checkIfOutputsReady()

  execute: ->
    @timer = setTimeout =>
      @onTimeout()
    , 5000
    @executeNthInput 0

  onTimeout: ->
    @subscriptions?.dispose()
    @runtime.stop()
    @onError "Your solutions didn't complete in 5 seconds!"

  destroy: ->


executeTasks = (runtime, inputs, onOutputs, onError) ->
  new TaskExecutor(runtime, inputs, onOutputs, onError).execute()


module.exports = executeTasks
