-- Copyright © 2017 coord.cn. All rights reserved.
-- @author      QianYe(coordcn@163.com)
-- @license     MIT license

local Request   = require("miss-server.src.request")
local Response  = require("miss-server.src.response")

local core      = require("miss-core")
local Object    = core.Object
local utils     = core.utils

local router    = require("miss-router")
local Router    = router.Router
local execute   = router.execute

local Server = Object:extend()

-- @param   options     {object}
--  local options = {
--      maxPathLength   = {number}
--      chunkSize       = {number}
--      timeout         = {number}
--      maxLineSize     = {number}
--      maxFileSize     = {number}
--      maxFileCount    = {number}
--      maxArgCount     = {number}
--      maxArgSize      = {number}
--  }
function Server:constructor(options)
    self.options        = options or {}
    self.router         = Router:new(self.options.maxPathLength)
    self.beforeHandles  = {}
    self.afterHandles   = {}
end

function Server:run()
    local path      = ngx.var.uri
    local method    = ngx.var.request_method

    local handles, params = self.router:find(method, path)

    if handles then
        local req = Request:new(path, method, params, self.options)
        local res = Response:new(method)

        execute(self.beforeHandles, handles, self.afterHandles, req, res)
        
        local ret = res:_output()
        if ret == false then
            ngx.log(ngx.ERR, res.error)
            ngx.exit(res.status)
            return
        end
    else
        ngx.exit(404)
    end
end

function Server:before(handle)
    table.insert(self.beforeHandles, handle)
end

function Server:after(handle)
    table.insert(self.afterHandles, handle)
end

function Server:add(method, path, handle)
    self.router:add(method, path, handle)
end

function Server:any(path, handle)
    self.router:add("ANY", path, handle)
end

function Server:get(path, handle)
    self.router:add("GET", path, handle)
end

function Server:post(path, handle)
    self.router:add("POST", path, handle)
end

function Server:put(path, handle)
    self.router:add("PUT", path, handle)
end

function Server:delete(path, handle)
    self.router:add("DELETE", path, handle)
end

function Server:patch(path, handle)
    self.router:add("PATCH", path, handle)
end

function Server:head(path, handle)
    self.router:add("HEAD", path, handle)
end

return Server
