{CompositeDisposable} = require 'atom'

class TaskExecutor

  TIME_LIMIT_IN_SECONDS = 10
  NO_OUTPUT_MSG = "For at least one of the inputs, your program hasn't " +
                  "written anything to the standard output."
  TOO_LONG_MSG = "Your program didn't produce outputs for all of the inputs " +
                 "in #{TIME_LIMIT_IN_SECONDS} seconds. Make sure you don't " +
                 "have any infinite loops in your code, etc."

  constructor: (@runtime, @inputs, @onOutputs, @onError) ->
    @outputs = []
    @finishedProcesses = 0
    @subscriptions = new CompositeDisposable
    @currentErrorOutputChunks = []
    @observeRuntime()
    @timer = null

  observeRuntime: ->
    @subscriptions.add @runtime.onDidWriteToStderr (ev) =>
      @currentErrorOutputChunks.push ev.message
    @subscriptions.add @runtime.onDidWriteToStdout (ev) =>
      @outputs.push ev.message.trim()
      @checkIfOutputsReady()
    @subscriptions.add @runtime.onDidNotRun (ev) =>
      @stopWithErrorMessage("Unable to run: #{ev.command}")
    @subscriptions.add @runtime.onDidNotSpecifyLanguage =>
      @stopWithErrorMessage("Language not specified")
    @subscriptions.add @runtime.onDidNotSupportLanguage (ev) =>
      @stopWithErrorMessage("Language not supported: #{ev.lang}")
    @subscriptions.add @runtime.onDidNotBuildArgs (ev) =>
      @stopWithErrorMessage("Unknown error: #{ev.error}")
    @subscriptions.add @runtime.onDidExit (ev) =>
      @onExit(ev.returnCode)

  checkIfOutputsReady: ->
    if @finishedProcesses > @outputs.length
      @stopWithErrorMessage NO_OUTPUT_MSG
    else if @finishedProcesses == @outputs.length
      if @finishedProcesses == @inputs.length
        @cleanUp()
        @onOutputs @outputs
      else
        @executeNthInput @finishedProcesses

  stopWithErrorMessage: (message) ->
    @cleanUp()
    @onError message

  cleanUp: ->
    clearTimeout @timer
    @runtime.stop()
    @subscriptions?.dispose()

  executeNthInput: (n) ->
    @currentErrorOutputChunks = []
    @runtime.stop()
    @runtime.execute "File Based", @inputs[n]

  onExit: (returnCode) ->
    if returnCode != 0
      errorMessage = @createMessageOnExit returnCode
      @stopWithErrorMessage errorMessage
    else
      ++@finishedProcesses
      @checkIfOutputsReady()

  createMessageOnExit: (returnCode) ->
    errorOutput = @currentErrorOutputChunks.join "\n"
    "Your program exited with code #{returnCode}. Error output:\n#{errorOutput}"

  execute: ->
    @timer = setTimeout =>
      @onTimeout()
    , 1000 * TIME_LIMIT_IN_SECONDS
    @executeNthInput 0

  onTimeout: ->
    @stopWithErrorMessage TOO_LONG_MSG

  destroy: ->
    @cleanUp()

executeTasks = (runtime, inputs, onOutputs, onError) ->
  new TaskExecutor(runtime, inputs, onOutputs, onError).execute()


module.exports = executeTasks
