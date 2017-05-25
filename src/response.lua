-- Copyright © 2017 coord.cn. All rights reserved.
-- @author      QianYe(coordcn@163.com)
-- @license     MIT license

local core = require("miss-core")
local Object = core.Object

local Response = Object:extend()

function Response:constructor()
end

function Response:setHeader()
end

function Response:setCookie()
end

-- @param       status  {number} 
function Response:status(status)
        self.status = status
end

-- @param       mime    {string}
function Response:type(mime)
        self.type = mime
end

-- @param       body    {string}
function Response:body(body)
        self.type = body
end

function Response:redirect(url, status)
end

function Response:download()
end

function Response:html()
end

function Response:text()
end

function Response:json()
end

function Response:xml()
end

function Response:jsonp()
end

return Response
