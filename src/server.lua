-- Copyright © 2017 coord.cn. All rights reserved.
-- @author      QianYe(coordcn@163.com)
-- @license     MIT license

local core      = require("miss-core")
local Object    = core.Object

local router    = require("miss-router")
local Router    = router.Router
local handle    = router.handle

local Server = Object:extend()

function Server:constructor()
end

function Server:run()
        -- ngx.status
        -- ngx.header
        local headers = ngx.req.get_headers()
        -- number second.ms
        local startTime = ngx.req.start_time()
        -- number 2.0 1.1 1.0 0.9
        local httpVersion = ngx.req.http_version()
        local method = ngx.var.request_method
        local path = ngx.req.
end

return Server
