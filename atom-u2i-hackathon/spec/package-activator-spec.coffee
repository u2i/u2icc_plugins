PackageActivator = require './../lib/package-activator'

describe 'PackageActivator', ->
  describe 'activatePackage', ->
    beforeEach ->
      @packageMock =
        activateNow: ->
      @packageManagerMock =
        activePackages: {}
        loadPackage: (name) -> null
      @subject = new PackageActivator(@packageManagerMock)

    it 'throws error if the package is not installed', ->
      activateFunc = =>
        @subject.activatePackage 'package1'

      expect(activateFunc).toThrow(
        new Error("Package not installed: 'package1'"))

    it 'calls activateNow on the package object', ->
      @packageManagerMock.loadPackage = (name) => @packageMock
      spyOn(@packageMock, 'activateNow')

      @subject.activatePackage 'package1'
      expect(@packageMock.activateNow).toHaveBeenCalled()

    it "does not load the package if it's active", ->
      @packageManagerMock.activePackages = {'package1': {}}
      spyOn(@packageManagerMock, 'loadPackage')
      spyOn(@packageMock, 'activateNow')

      console.log @packageManagerMock.loadPackage
      console.log @packageMock.activateNow

      @subject.activatePackage 'package1'

      expect(@packageManagerMock.loadPackage.calls.length).toEqual 0
      expect(@packageMock.activateNow.calls.length).toEqual 0

  describe 'activatePackages', ->
    beforeEach ->
      @packageManagerMock =
        activePackages: []
        deactivatePackage: (name) -> {}
        loadPackage: (name) ->

      @subject = new PackageActivator(@packageManagerMock)
      spyOn(@packageManagerMock, 'deactivatePackage')

    it 'activates given packages', ->
      spyOn(@subject, 'activatePackage')
      @subject.activatePackages(['package1'])
      expect(@subject.activatePackage).toHaveBeenCalledWith('package1')

    it 'deactivates previously activated packages', ->
      spyOn(@subject, 'activatePackage')
      @subject.activatePackages(['package1'])
      @subject.activatePackages(['package2'])

      expect(@packageManagerMock.deactivatePackage).toHaveBeenCalledWith('package1')
      expect(@subject.activatePackage).toHaveBeenCalledWith('package2')

  describe 'deactivatePackages', ->
    beforeEach ->
      @packageManagerMock =
        enablePackage: (name) -> {}
        deactivatePackage: (name) -> {}

      @subject = new PackageActivator(@packageManagerMock)
      spyOn(@packageManagerMock, 'deactivatePackage')

    it 'asks PackageManager to disable current packages', ->
      @subject.currentPackageNames = ['package1', 'package2']

      @subject.deactivatePackages()

      expect(@packageManagerMock.deactivatePackage).toHaveBeenCalledWith('package1')
      expect(@packageManagerMock.deactivatePackage).toHaveBeenCalledWith('package2')
      expect(@subject.currentPackageNames).toEqual([])
