HttpUtils = require '../utils/http-utils'
logger = require '../utils/logger'

class MockGetHandler extends HttpUtils
  resolve: (req, res, methodInfo) ->
    logger.debug "Mock resolved - GET #{req.url}"
    @setDefaultHeaders res, methodInfo
    @negotiateAcceptType req, res, methodInfo

# Remove this code!
class GetHandler extends HttpUtils
  constructor: (@apiPath, @context, @resources) ->

  resolve: (uriTemplate, handler) =>
    @context.get uriTemplate, (req, res) =>
      methodInfo = @methodLookup @resources, 'get', uriTemplate
      @negotiateAcceptType req, res, methodInfo, handler

exports.MockHandler = MockGetHandler
exports.Handler = GetHandler
