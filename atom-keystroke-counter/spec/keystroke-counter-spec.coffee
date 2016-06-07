KeystrokeCounter = require '../lib/keystroke-counter'

describe "KeystrokeCounter", ->

  createMockSubscription = (methodName) ->
    jasmine.createSpyObj("#{methodName}Subscription", ['dispose'])

  createMockBuffer = (id) ->
    id: id
    onDidChange: jasmine.createSpy("#{id}.onDidChange")
    onDidDestroy: jasmine.createSpy("#{id}.onDidDestroy")

  beforeEach ->
    @keystrokeCounter = new KeystrokeCounter

    @onDidChangeSubscription = createMockSubscription('onDidChange')
    @onDidDestroySubscription = createMockSubscription('onDidDestroy')
    @mockBuffer = createMockBuffer('12345678')
    @mockBuffer.onDidChange.andReturn @onDidChangeSubscription
    @mockBuffer.onDidDestroy.andReturn @onDidDestroySubscription

    @mockEditor =
      getBuffer: => @mockBuffer
    @mockWorkspaceSubscription = createMockSubscription('observeTextEditors')
    spyOn(atom.workspace, 'observeTextEditors').andReturn @mockWorkspaceSubscription

  describe ".start", ->
    beforeEach ->
      @keystrokeCounter.start()
      spyOn(@keystrokeCounter, 'observeBuffer')

    it "starts with a count of 0", ->
      expect(@keystrokeCounter.getCount()).toEqual 0

    it "starts observing text editors", ->
      expect(atom.workspace.observeTextEditors).toHaveBeenCalled()

    it "registers a callback to be called on a text editor", ->
      registeredCallback = atom.workspace.observeTextEditors.mostRecentCall.args[0]
      registeredCallback(@mockEditor)

      expect(@keystrokeCounter.observeBuffer).toHaveBeenCalledWith(@mockBuffer)

    describe "starting again without stopping", ->
      it "does not observe text editors again", ->
        @keystrokeCounter.start()

        expect(atom.workspace.observeTextEditors.calls.length).toEqual 1

      it "does not reset the count to 0", ->
        @keystrokeCounter.observeBuffer.andCallThrough()
        @keystrokeCounter.observeBuffer(@mockBuffer)

        onDidChangeCallback = @mockBuffer.onDidChange.mostRecentCall.args[0]
        onDidChangeCallback oldText: 'old', newText: 'new'
        onDidChangeCallback oldText: 'old', newText: 'new'
        @keystrokeCounter.start()

        expect(@keystrokeCounter.getCount()).toEqual 2

    describe "starting again after stopping", ->
      it "starts observing text editors again", ->
        @keystrokeCounter.stop()
        @keystrokeCounter.start()

        expect(atom.workspace.observeTextEditors.calls.length).toEqual 2

      it "resets the count to 0 even if changes to buffers have been made", ->
        @keystrokeCounter.observeBuffer.andCallThrough()
        @keystrokeCounter.observeBuffer(@mockBuffer)

        onDidChangeCallback = @mockBuffer.onDidChange.mostRecentCall.args[0]
        onDidChangeCallback oldText: 'old', newText: 'new'
        onDidChangeCallback oldText: 'old', newText: 'new'
        @keystrokeCounter.stop()
        @keystrokeCounter.start()

        expect(@keystrokeCounter.getCount()).toEqual 0

  describe ".observeBuffer", ->
    beforeEach ->
      @keystrokeCounter.observeBuffer(@mockBuffer)

      @otherBuffer = createMockBuffer('differentId')

    it "registers a callback with buffer's 'onDidChange' method", ->
      expect(@mockBuffer.onDidChange).toHaveBeenCalled()

    describe "callback registered with 'onDidChange'", ->
      beforeEach ->
        @onDidChangeCallback = @mockBuffer.onDidChange.mostRecentCall.args[0]

      it "increases the count if the buffer's text has changed", ->
        @onDidChangeCallback oldText: 'old', newText: 'new'

        expect(@keystrokeCounter.getCount()).toEqual 1

      it "leaves the count unchanged unless the buffer's text has changed", ->
        @onDidChangeCallback oldText: 'old', newText: 'old'

        expect(@keystrokeCounter.getCount()).toEqual 0

    it "registers a callback with buffer's 'onDidDestroy' method", ->
      expect(@mockBuffer.onDidDestroy).toHaveBeenCalled()

    describe "callback registered with 'onDidDestroy'", ->
      beforeEach ->
        @onDidDestroyCallback = @mockBuffer.onDidDestroy.mostRecentCall.args[0]

      it "disposes this buffer's subscriptions", ->
        @onDidDestroyCallback()

        expect(@onDidChangeSubscription.dispose).toHaveBeenCalled()
        expect(@onDidDestroySubscription.dispose).toHaveBeenCalled()

      it "does not dispose subscriptions of other buffers", ->
        otherBufferChangeSubscription = createMockSubscription('otherBufferChange')
        otherBufferDestroySubscription = createMockSubscription('otherBufferDestroy')
        @otherBuffer.onDidChange.andReturn otherBufferChangeSubscription
        @otherBuffer.onDidDestroy.andReturn otherBufferDestroySubscription
        @keystrokeCounter.observeBuffer(@otherBuffer)

        @onDidDestroyCallback()

        expect(otherBufferChangeSubscription.dispose).not.toHaveBeenCalled()
        expect(otherBufferDestroySubscription.dispose).not.toHaveBeenCalled()

    it "does not observe the same buffer twice", ->
      @keystrokeCounter.observeBuffer(@mockBuffer)

      expect(@mockBuffer.onDidChange.calls.length).toEqual(1)
      expect(@mockBuffer.onDidDestroy.calls.length).toEqual(1)

    it "may observe multiple buffers", ->
      differentBuffer =
        id: 'differentId'
        onDidChange: jasmine.createSpy('onDidChange')
        onDidDestroy: jasmine.createSpy('onDidDestroy')

      @keystrokeCounter.observeBuffer(differentBuffer)

      expect(differentBuffer.onDidChange).toHaveBeenCalled()
      expect(differentBuffer.onDidDestroy).toHaveBeenCalled()

    it "may observe the same buffer again after stopping and starting", ->
      @keystrokeCounter.stop()
      @keystrokeCounter.start()
      @keystrokeCounter.observeBuffer(@mockBuffer)

      expect(@mockBuffer.onDidChange.calls.length).toEqual(2)
      expect(@mockBuffer.onDidDestroy.calls.length).toEqual(2)

  describe ".stop", ->
    beforeEach ->
      @otherBuffer = createMockBuffer('differentId')
      @otherBufferChangeSubscription = createMockSubscription('otherBufferChange')
      @otherBufferDestroySubscription = createMockSubscription('otherBufferDestroy')
      @otherBuffer.onDidChange.andReturn @otherBufferChangeSubscription
      @otherBuffer.onDidDestroy.andReturn @otherBufferDestroySubscription

      @keystrokeCounter.start()
      @keystrokeCounter.observeBuffer @mockBuffer
      @keystrokeCounter.observeBuffer @otherBuffer
      console.log 'STOP1'
      @keystrokeCounter.stop()

    it "stops observing text editors (disposes the subscription)", ->
      expect(@mockWorkspaceSubscription.dispose).toHaveBeenCalled()

    it "disposes all subscriptions to buffer events", ->
      for subscription in [@onDidChangeSubscription, @onDidDestroySubscription, @otherBufferChangeSubscription, @otherBufferDestroySubscription]
        expect(subscription.dispose).toHaveBeenCalled()

  describe ".destroy", ->
    it "calls .stop", ->
      spyOn(@keystrokeCounter, 'stop')

      @keystrokeCounter.destroy()

      expect(@keystrokeCounter.stop).toHaveBeenCalled()

  describe ".reportCountPeriodically", ->
    beforeEach ->
      @keystrokeCounter.start()
      @keystrokeCounter.observeBuffer @mockBuffer
      @onDidChangeCallback = @mockBuffer.onDidChange.mostRecentCall.args[0]
      @interval = 5000
      jasmine.Clock.useMock()
      @callback = jasmine.createSpy 'reportCountPeriodicallyCallback'
      @anotherCallback = jasmine.createSpy 'reportCountPeriodicallyAnotherCallback'

    it "periodically executes the given callback", ->
      @keystrokeCounter.reportCountPeriodically @interval, @callback
      expect(@callback).not.toHaveBeenCalled()

      [1..3].forEach (n) =>
        jasmine.Clock.tick @interval
        expect(@callback.calls.length).toEqual n

    it "passes the current count to the callback", ->
      @keystrokeCounter.reportCountPeriodically @interval, @callback
      expect(@callback).not.toHaveBeenCalled()

      [1..3].forEach (n) =>
        @onDidChangeCallback oldText: 'old', newText: 'new'
        jasmine.Clock.tick @interval
        expect(@callback.mostRecentCall.args[0]).toEqual n

    it "may be called multiple times to register multiple callbacks", ->
      @keystrokeCounter.reportCountPeriodically @interval, @callback
      @keystrokeCounter.reportCountPeriodically 1.5 * @interval, @anotherCallback

      jasmine.Clock.tick @interval
      expect(@callback.calls.length).toEqual 1
      expect(@anotherCallback.calls.length).toEqual 0

      jasmine.Clock.tick @interval
      expect(@callback.calls.length).toEqual 2
      expect(@anotherCallback.calls.length).toEqual 1

    it "unschedules all callbacks after .stop has been called", ->
      @keystrokeCounter.reportCountPeriodically @interval, @callback
      @keystrokeCounter.reportCountPeriodically @interval, @anotherCallback

      jasmine.Clock.tick @interval
      expect(@callback.calls.length).toEqual 1
      expect(@anotherCallback.calls.length).toEqual 1

      @keystrokeCounter.stop()

      jasmine.Clock.tick @interval
      expect(@callback.calls.length).toEqual 1
      expect(@anotherCallback.calls.length).toEqual 1

  describe ".reportCountOnChange", ->
    beforeEach ->
      @keystrokeCounter.start()
      @keystrokeCounter.observeBuffer @mockBuffer
      @onDidChangeCallback = @mockBuffer.onDidChange.mostRecentCall.args[0]

      @callback = jasmine.createSpy 'reportCountPeriodicallyCallback'

    it "calls the callback when the count changes", ->
      @keystrokeCounter.reportCountOnChange @callback
      expect(@callback.calls.length).toEqual 0

      @onDidChangeCallback oldText: 'old', newText: 'new'
      expect(@callback.calls.length).toEqual 1
      expect(@callback.mostRecentCall.args[0]).toEqual 1

      @onDidChangeCallback oldText: 'old', newText: 'new'
      expect(@callback.calls.length).toEqual 2
      expect(@callback.mostRecentCall.args[0]).toEqual 2

      @keystrokeCounter.stop()
      expect(@callback.calls.length).toEqual 2

      @keystrokeCounter.start()
      expect(@callback.calls.length).toEqual 3
      expect(@callback.mostRecentCall.args[0]).toEqual 0
