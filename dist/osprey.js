(function() {
  var DefaultParameters, ErrorHandler, Osprey, OspreyBase, Promise, express, fs, path, url,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  express = require('express');

  path = require('path');

  DefaultParameters = require('./middlewares/default-parameters');

  ErrorHandler = require('./middlewares/error-handler');

  OspreyBase = require('./osprey-base');

  fs = require('fs');

  url = require('url');

  Promise = require('bluebird');

  Osprey = (function(_super) {
    __extends(Osprey, _super);

    function Osprey() {
      this.describe = __bind(this.describe, this);
      this.registerConsole = __bind(this.registerConsole, this);
      this.register = __bind(this.register, this);
      return Osprey.__super__.constructor.apply(this, arguments);
    }

    Osprey.prototype.register = function(uriTemplateReader, resources) {
      var middlewares;
      middlewares = [];
      middlewares.push(ErrorHandler);
      return this.registerMiddlewares(middlewares, this.context, this.settings, resources, uriTemplateReader, this.logger);
    };

    Osprey.prototype.registerConsole = function() {
      if (this.settings.enableConsole) {
        this.context.get(this.settings.consolePath, this.consoleHandler(this.context.route, this.settings.consolePath));
        this.context.get(url.resolve(this.settings.consolePath + '/', 'index.html'), this.consoleHandler(this.context.route, this.settings.consolePath));
        this.context.use(this.settings.consolePath, express["static"](path.join(__dirname, 'assets/console')));
        this.context.get('/', this.ramlHandler(this.settings.ramlFile));
        this.context.use('/', express["static"](path.dirname(this.settings.ramlFile)));
        return this.logger.info("Osprey::APIConsole has been initialized successfully listening at " + (this.context.route + this.settings.consolePath));
      }
    };

    Osprey.prototype.consoleHandler = function(apiPath, consolePath) {
      return function(req, res) {
        var filePath;
        filePath = path.join(__dirname, '/assets/console/index.html');
        return fs.readFile(filePath, function(err, data) {
          data = data.toString().replace(/apiPath/gi, apiPath);
          data = data.toString().replace(/resourcesPath/gi, apiPath + consolePath);
          res.set('Content-Type', 'text/html');
          return res.send(data);
        });
      };
    };

    Osprey.prototype.ramlHandler = function(ramlPath) {
      return function(req, res) {
        var baseUri;
        if (req.accepts('application/raml+yaml') != null) {
          baseUri = "http" + (req.secure ? 's' : '') + "://" + req.headers.host + req.originalUrl;
          return fs.readFile(ramlPath, function(err, data) {
            data = data.toString().replace(/^baseUri:.*$/gmi, "baseUri: " + baseUri);
            res.set('Content-Type', 'application/raml+yaml');
            return res.send(data);
          });
        } else {
          return res.send(406);
        }
      };
    };

    Osprey.prototype.load = function(err, uriTemplateReader, resources) {
      if (err == null) {
        if ((this.apiDescriptor != null) && typeof this.apiDescriptor === 'function') {
          this.apiDescriptor(this.context);
        }
        return this.register(uriTemplateReader, resources);
      }
    };

    Osprey.prototype.describe = function(descriptor) {
      this.apiDescriptor = descriptor;
      return Promise.resolve(this.context.parent);
    };

    Osprey.prototype.mount = function(basePath, app) {
      return app.use(basePath, this.context);
    };

    return Osprey;

  })(OspreyBase);

  module.exports = Osprey;

}).call(this);
