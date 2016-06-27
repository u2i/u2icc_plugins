fs = require 'fs'
path = require 'path'

SnippetProvider = require './../lib/snippet-provider'

snippetDir = path.join __dirname, '../codeSnippets'

describe 'SnippetProvider', ->
  [snippetProvider] = []

  describe 'provide', ->
    extension = 'nonexistentextension'
    snippetPath = path.join snippetDir, "snippet.#{extension}"
    expectedSnippet = 'aaa\nbbb\nccc'

    writeFilePromise = (filePath, string, options) ->
      new Promise (resolve, reject) ->
        fs.writeFile filePath, string, options, (err) ->
          if err then reject(err) else resolve()

    expectSnippet = (expectedSnippet) ->
      waitsForPromise ->
        snippetProvider.provide(extension).then (actualSnippet) ->
          expect(actualSnippet).toEqual expectedSnippet

    beforeEach ->
      snippetProvider = new SnippetProvider

    afterEach ->
      waitsForPromise ->
        new Promise (resolve, reject) ->
          fs.access snippetPath, (err) ->
            if err
              resolve()
            else
              fs.unlink snippetPath, (err) ->
                if err then reject(err) else resolve()

    it 'returns a promise resolving to the snippet for the given file extension', ->
      waitsForPromise ->
        writeFilePromise snippetPath, expectedSnippet

      expectSnippet expectedSnippet

    it 'returns a promise resolving to an empty string if the file is missing', ->
      expectSnippet ''

    it 'returns a promise resolving to an empty string if the file cannot be read', ->
      waitsForPromise ->
        writeFilePromise snippetPath, expectedSnippet, mode: 0o066

      expectSnippet ''
