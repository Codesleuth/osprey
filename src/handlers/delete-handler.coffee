HttpUtils = require '../utils/http-utils'
logger = require '../utils/logger'

class MockDeleteHandler extends HttpUtils
  resolve: (req, res, methodInfo) ->
    logger.debug "Mock resolved - DELETE #{req.url}"
    @setDefaultHeaders res, methodInfo
    res.send @readStatusCode(methodInfo)

class DeleteHandler extends HttpUtils
  constructor: (@apiPath, @context, @resources) ->

  resolve: (uriTemplate, handler) =>
    @context.delete uriTemplate, (req, res) ->
      handler req, res

exports.MockHandler = MockDeleteHandler
exports.Handler = DeleteHandler
