express = require 'express'
path = require 'path'
DefaultParameters = require './middlewares/default-parameters'
ErrorHandler = require './middlewares/error-handler'
OspreyBase = require './osprey-base'
fs = require 'fs'
url = require 'url'
Promise = require 'bluebird'

class Osprey extends OspreyBase
  register: (uriTemplateReader, resources) =>
    middlewares = []

    middlewares.push ErrorHandler

    @registerMiddlewares middlewares, @context, @settings, resources, uriTemplateReader, @logger

  registerConsole: () =>
    if @settings.enableConsole
      @context.get @settings.consolePath, @consoleHandler(@context.route, @settings.consolePath)
      @context.get url.resolve(@settings.consolePath + '/', 'index.html'), @consoleHandler(@context.route, @settings.consolePath)
      @context.use @settings.consolePath, express.static(path.join(__dirname, 'assets/console'))

      @context.get '/', @ramlHandler(@settings.ramlFile)
      @context.use '/', express.static(path.dirname(@settings.ramlFile))

      @logger.info "Osprey::APIConsole has been initialized successfully listening at #{@context.route + @settings.consolePath}"

  consoleHandler: (apiPath, consolePath) ->
    (req, res) ->
      filePath = path.join __dirname, '/assets/console/index.html'

      fs.readFile filePath, (err, data) ->
        data = data.toString().replace(/apiPath/gi, apiPath)
        data = data.toString().replace(/resourcesPath/gi, apiPath+consolePath)
        res.set 'Content-Type', 'text/html'
        res.send data

  ramlHandler: (ramlPath) ->
    (req, res) ->
      if req.accepts('application/raml+yaml')?
        baseUri = "http#{if req.secure then 's' else ''}://#{req.headers.host}#{req.originalUrl}"

        fs.readFile ramlPath, (err, data) ->
          data = data.toString().replace(/^baseUri:.*$/gmi, "baseUri: #{baseUri}")
          res.set 'Content-Type', 'application/raml+yaml'
          res.send data
      else
        res.send 406

  load: (err, uriTemplateReader, resources) ->
    unless err?
      if @apiDescriptor? and typeof @apiDescriptor == 'function'
        @apiDescriptor @context

      @register(uriTemplateReader, resources)

  # Temporary Hack
  describe: (descriptor) =>
    @apiDescriptor = descriptor
    Promise.resolve @context.parent

  # Temporary Hack
  mount: (basePath, app) ->
    app.use basePath, @context

module.exports = Osprey
