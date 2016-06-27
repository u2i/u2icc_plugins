fs = require 'fs'
path = require 'path'

snippetDir = path.join __dirname, '../codeSnippets'

module.exports =
  class SnippetProvider

    provide: (fileExtension) ->
      snippetPath = path.join snippetDir, "snippet.#{fileExtension}"
      new Promise (resolve, reject) ->
        fs.readFile snippetPath, (err, content) ->
          if err
            resolve ''
          else
            resolve content.toString()
