-- Copyright © 2017 coord.cn. All rights reserved.
-- @author      QianYe(coordcn@163.com)
-- @license     MIT license

local handles   = require("miss-server.src.handles")
local core      = require("miss-core")
local Object    = core.Object
local MIME      = core.MIME

local Response  = Object:extend()

-- @property    type    {string}                    mime type
-- @property    charset {string|default: utf-8}     charset
-- @property    status  {number}                    http status
-- @property    error   {string}                    error
function Response:constructor(method)
    self.method     = method
    self._headers   = {}
    self._cookies   = {}
end

function Response:setHeader(key, value)
    self._headers[key] = value
end

function Response:setCookie(key, value)
    self._cookies[key] = value
end

-- @param   input   {string}
function Response:body(input, mime)
    self._handle    = "body"
    self._input     = input
    if mime then
        self.type = mime
    end
end

-- @param   input   {object}
--  local input = {
--      url     = {string}
--      status  = {number}
--      body    = {string}
--      type    = {string}
--  }
function Response:redirect(input)
    self._handle    = "redirect"
    self._input     = input
    if mime then
        self.type = mime
    end
end

-- @brief   for test, not for product, maybe block the socket
-- @param   input   {object}
--  local input = {
--      inline      = {boolean|default: false}
--      filename    = {string}
--      extname     = {string}
--      path        = {string}
--      data        = {string}
--      type        = {string}
--  }
function Response:download(input)
    self._handle    = "download"
    self._input     = input
    if mime then
        self.type = mime
    end
end

-- @param   input   {string}
function Response:html(input)
    self._handle    = "html"
    self._input     = input
end

-- @param   input   {string}
function Response:text(input)
    self._handle    = "text"
    self._input     = input
end

-- @param   input   {object|array}
function Response:json(input)
    self._handle    = "json"
    self._input     = input
end

-- @param   input   {object}
function Response:xml(input)
    self._handle    = "xml"
    self._input     = input
end

-- @param   callback    {string}
-- @param   input       {object|array}
function Response:jsonp(callback, input)
    self._handle    = "jsonp"
    self._callback  = callback
    self._input     = input
end

function Response:_output()
    local handle = handles[self._handle]

    if handle then
        return handle(self) 
    end
end

return Response
