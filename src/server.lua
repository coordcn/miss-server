-- Copyright © 2017 coord.cn. All rights reserved.
-- @author      QianYe(coordcn@163.com)
-- @license     MIT license

local core      = require("miss-core")
local Object    = core.Object
local utils     = core.utils

local router    = require("miss-router")
local Router    = router.Router
local handle    = router.handle

local Server = Object:extend()

-- @param       options         {object}
--      local options = {
--              chunkSize       = {number}
--              timeout         = {number}
--              maxLineSize     = {number}
--              maxFileSize     = {number}
--              maxFileCount    = {number}
--              maxArgCount     = {number}
--              maxArgSize      = {number}
--      }
function Server:constructor(options)
        self.options            = options
        self.router             = Router:new(self.options.maxPathLength)
        self.beforeHandles      = {}
        self.afterHandles       = {}
end

function Server:run()
        local path      = ngx.var.uri
        local method    = ngx.var.request_method

        local handles, params = self.router:find(method, path)

        if handles then
        else
        end


        -- ngx.status
        -- ngx.header
        local headers = ngx.req.get_headers()
        -- number second.ms
        local startTime = ngx.req.start_time()
        -- number 2.0 1.1 1.0 0.9
        local httpVersion = ngx.req.http_version()
        local req_uri = ngx.var.request_uri


end

function Server:error(status, handle)
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
