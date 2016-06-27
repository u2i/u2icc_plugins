PackageActivator = require './../lib/package-activator'

describe 'PackageActivator', ->
  describe 'activatePackage', ->
    beforeEach ->
      @activePackages = []
      @packageMock =
        activateNow: ->
      @packageManagerMock =
        isPackageActive: (name) => name in @activePackages
        loadPackage: (name) -> null
      @subject = new PackageActivator(@packageManagerMock)

    it 'throws error if the package is not installed', ->
      activateFunc = => @subject.activatePackage 'package1'

      expect(activateFunc).toThrow(
        new Error("Package not installed: 'package1'"))

    it 'calls activateNow on the package object', ->
      @packageManagerMock.loadPackage = (name) => @packageMock
      spyOn(@packageMock, 'activateNow')

      @subject.activatePackage 'package1'
      expect(@packageMock.activateNow).toHaveBeenCalled()

    it "does not load the package if it's active", ->
      @activePackages = ['package1']
      spyOn(@packageManagerMock, 'loadPackage')
      spyOn(@packageMock, 'activateNow')

      @subject.activatePackage 'package1'

      expect(@packageManagerMock.loadPackage.calls.length).toEqual 0
      expect(@packageMock.activateNow.calls.length).toEqual 0

  describe 'activatePackages', ->
    beforeEach ->
      @packageManagerMock =
        activePackages: []
        deactivatePackage: (name) -> {}
        loadPackage: (name) ->

      @subject = new PackageActivator @packageManagerMock
      spyOn(@subject, 'deactivatePackages')
      spyOn @subject, 'activatePackage'

    it 'activates given packages', ->
      @subject.activatePackages ['package1']
      expect(@subject.activatePackage).toHaveBeenCalledWith 'package1'

    it 'returns a result indicating that no package failed to be loaded', ->
      returnValue = @subject.activatePackages ['package1']
      expect(returnValue).toEqual failedPackages: []

    it "sets the 'currentPackageNames' field", ->
      @subject.activatePackages ['package1']
      expect(@subject.currentPackageNames).toEqual ['package1']

    it 'deactivates previously activated packages', ->
      @subject.currentPackageNames = ['package1']
      @subject.deactivatePackages.andCallFake =>
        expect(@subject.currentPackageNames).toEqual ['package1']

      @subject.activatePackages ['package2']

      expect(@subject.deactivatePackages).toHaveBeenCalled()
      expect(@subject.currentPackageNames).toEqual ['package2']
      expect(@subject.activatePackage).toHaveBeenCalledWith 'package2'

    describe 'when a package fails to be loaded', ->
      beforeEach ->
        @failingName = 'bad'
        @subject.activatePackage.andCallFake (packageName) =>
          if packageName == @failingName
            throw new Error "Package not installed: '#{@failingName}'"

      it 'does not throw any error', ->
        methodCall = => @subject.activatePackages [@failingName]

        expect(methodCall).not.toThrow()

      it 'activates the remaining packages', ->
        @subject.activatePackages ['p1', @failingName, 'p2']
        ['p1', 'p2'].forEach (name) =>
          expect(@subject.activatePackage).toHaveBeenCalledWith name

      it 'returns a result containing a list of packages having failed', ->
        returnValue = @subject.activatePackages ['p1', @failingName, 'p2']
        expect(returnValue).toEqual failedPackages: [@failingName]

      it "sets the 'currentPackageNames' field to successfully activated packages", ->
        returnValue = @subject.activatePackages ['p1', @failingName, 'p2']
        expect(@subject.currentPackageNames).toEqual ['p1', 'p2']

  describe 'deactivatePackages', ->
    beforeEach ->
      @packageManagerMock =
        enablePackage: (name) -> {}
        deactivatePackage: (name) -> {}

      @subject = new PackageActivator @packageManagerMock
      spyOn @packageManagerMock, 'deactivatePackage'

    it 'asks PackageManager to disable current packages', ->
      @subject.currentPackageNames = ['package1', 'package2']

      @subject.deactivatePackages()

      expect(@packageManagerMock.deactivatePackage).toHaveBeenCalledWith('package1')
      expect(@packageManagerMock.deactivatePackage).toHaveBeenCalledWith('package2')
      expect(@subject.currentPackageNames).toEqual([])
