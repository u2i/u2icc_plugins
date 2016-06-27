module.exports =
class PackageActivator

  constructor: (@packageManager = atom.packages) ->
    @currentPackageNames = []

  # Public
  #
  # Call this function only when you want to activate a single package and if you don't
  # care that it should be stopped later.
  activatePackage: (packageName) ->
    return if @packageManager.isPackageActive packageName

    # There's no easy way to use PackageManager to force activate a package
    # As of 9.09.2015 this is the way to go
    pakage = @packageManager.loadPackage packageName

    throw new Error("Package not installed: '#{packageName}'") unless pakage?

    pakage.activateNow()

  # Public
  #
  # Multiple call to this function will deactivate previously activated packages
  activatePackages: (packageNames) ->
    @deactivatePackages()
    @currentPackageNames = []
    failedPackages = []

    for packageName in packageNames
      try
        @activatePackage packageName
        @currentPackageNames.push packageName
      catch
        failedPackages.push packageName

    failedPackages: failedPackages

  deactivatePackages: ->
    for packageName in @currentPackageNames
      @packageManager.deactivatePackage packageName

    @currentPackageNames = []
