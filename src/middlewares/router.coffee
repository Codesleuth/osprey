GetMethod = require '../handlers/get-handler'
PostMethod = require '../handlers/post-handler'
PutMethod = require '../handlers/put-handler'
DeleteMethod = require '../handlers/delete-handler'
HeadMethod = require '../handlers/head-handler'
PatchMethod = require '../handlers/patch-handler'
RamlHelper = require '../utils/raml-helper'

class OspreyRouter extends RamlHelper
  constructor: (@context, @settings, @resources, @uriTemplateReader, @logger) ->
    @logger.info 'Osprey::Router has been initialized successfully'

    @mockMethodHandlers =
      get: new GetMethod.MockHandler
      post: new PostMethod.MockHandler
      put: new PutMethod.MockHandler
      delete: new DeleteMethod.MockHandler
      head: new HeadMethod.MockHandler
      patch: new PatchMethod.MockHandler

    @methodHandlers =
      get: new GetMethod.Handler @context.route, @context, @resources
      post: new PostMethod.Handler @context.route, @context, @resources
      put: new PutMethod.Handler @context.route, @context, @resources
      delete: new DeleteMethod.Handler @context.route, @context, @resources
      head: new HeadMethod.Handler @context.route, @context, @resources
      patch: new PatchMethod.Handler @context.route, @context, @resources

    if @settings.handlers?
      for handler in @settings.handlers
        @resolveMethod handler

  exec: (req, res, next) =>
    @resolveMock req, res, next, @settings.enableMocks

  resolveMock: (req, res, next, enableMocks) =>
    uri = req.url.split('?')[0]
    template = @uriTemplateReader.getTemplateFor uri
    method = req.method.toLowerCase()
    enableMocks = true unless enableMocks?

    if template? and not @routerExists method, uri
      methodInfo = @methodLookup @resources, method, template.uriTemplate

      if methodInfo? and enableMocks
        @mockMethodHandlers[method].resolve req, res, methodInfo
        return

    next()

  routerExists: (httpMethod, uri) =>
    if @context.routes[httpMethod]?
      result = @context.routes[httpMethod].filter (route) ->
        uri.match(route.regexp)?.length

    result? and result.length is 1

  # TODO: Refactor
  resolveMethod: (config) =>
    resourceExists = @resources[config.template]?.methods?.filter (info) -> info.method == config.method
    if resourceExists? and resourceExists.length > 0
      if config.handler
        @logger.debug "Overwritten resource - #{config.method.toUpperCase()} #{config.template}"
        @methodHandlers[config.method].resolve config.template, config.handler
      else
        @logger.error "Resource to overwrite does not have handlers defined - #{config.method.toUpperCase()} #{config.template}"
    else
      @logger.error "Resource to overwrite does not exists - #{config.method.toUpperCase()} #{config.template}"

module.exports = OspreyRouter
