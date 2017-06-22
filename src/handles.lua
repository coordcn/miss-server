-- Copyright © 2017 coord.cn. All rights reserved.
-- @author      QianYe(coordcn@163.com)
-- @license     MIT license

local cjson     = require("cjson.safe")
local core      = require("miss-core")
local MIME      = core.MIME
local xml       = core.xml
local cookie    = core.cookie
local uri       = core.uri
local utils     = core.utils

local _M = {}

local function setHeaders(headers)
        for key, value in pairs(headers) do
                ngx.header[key] = value
        end
end

function _M.body(res)
        cookie.set(res._cookies)

        local output = res._input
        if output then
                if type(output) ~= "string" then
                        error("Response:body(input) input must be string")
                end

                local mime = res.type or MIME.TEXT
                local charset = res.charset
                local headers = res._headers
                if charset then
                        headers["Content-Type"] = mime .. ";charset=" .. charset
                else
                        headers["Content-Type"] = mime
                end
                headers["Content-Length"] = #output
                setHeaders(headers)

                local ok, err = ngx.say(output)
                if not ok then
                        res.status      = ngx.HTTP_INTERNAL_SERVER_ERROR
                        res.error       = err
                        return false
                end
        else
                setHeaders(res._headers)
        end

        return true
end

function _M.redirect(res)
        cookie.set(res._cookies)
        
        local input = res._input
        local output = input.body
        if output then
                if type(output) ~= "string" then
                        error("Response:redirect(input) input.body must be string")
                end

                local mime = res.type or MIME.TEXT
                local charset = res.charset
                local headers = res._headers
                if charset then
                        headers["Content-Type"] = mime .. ";charset=" .. charset
                else
                        headers["Content-Type"] = mime
                end
                headers["Content-Length"] = #output
                setHeaders(headers)

                local ok, err = ngx.say(output)
                if not ok then
                        res.status      = ngx.HTTP_INTERNAL_SERVER_ERROR
                        res.error       = err
                        return false
                end
        else
                setHeaders(res._headers)
        end

        ngx.redirect(input.url, input.status)
        return true
end

function _M.download(res)
        local input = res._input
        local data = input.data
        local path = input.path

        local output
        if data then
                if type(data) ~= "string" then
                        error("Response:download(input) input.data must be string")
                end

                output = data
        elseif path then
                if type(path) ~= "string" then
                        error("Response:download(input) input.path must be string")
                end

                file, err = io.open(path)
                if not file then
                        res.status = ngx.HTTP_NOT_FOUND
                        res.error = "Response:download(input) file not found"
                        return false
                end

                output = file:read("*a")
                file:close()
        else
                error("Response:download(input) input.data or input.path required")
        end

        local filename = input.filename
        if type(filename) ~= "string" then
                error("Response:download(input) input.filename must be string")
        end

        local extname = input.extname
        if type(extname) ~= "string" then
                error("Response:download(input) input.extname must be string")
        end

        filename = uri.encode(filename) .. '.' .. extname
        local attachment = "attachment;"
        if input.inline then
                attachment = "inline;"
        end
                
        local headers = res._headers
        headers["Content-Type"]         = MIME[string.upper(extname)] or MIME.OCTET
        headers["Content-Length"]       = #output
        headers["Content-Disposition"]  = attachment .. 
                                          'filename="' .. filename .. '";' ..
                                          "filename*=utf-8''" .. filename
        setHeaders(headers)
        cookie.set(res._cookies)

        local ok, err = ngx.say(output)
        if not ok then
                res.status      = ngx.HTTP_INTERNAL_SERVER_ERROR
                res.error       = err
                return false
        end

        return true
end

function _M.html(res)
        cookie.set(res._cookies)

        local output = res._input
        if output then
                if type(output) ~= "string" then
                        error("Response:html(input) input must be string")
                end

                local mime = res.type or MIME.HTML
                local charset = res.charset or "utf-8"
                local headers = res._headers
                headers["Content-Type"]         = mime .. ";charset=" .. charset
                headers["Content-Length"]       = #output
                setHeaders(headers)

                local ok, err = ngx.say(output)
                if not ok then
                        res.status      = ngx.HTTP_INTERNAL_SERVER_ERROR
                        res.error       = err
                        return false
                end
        else
                setHeaders(res._headers)
        end

        return true
end

function _M.text(res)
        cookie.set(res._cookies)

        local output = res._input
        if output then
                if type(output) ~= "string" then
                        error("Response:text(input) input must be string")
                end

                local mime = res.type or MIME.TEXT
                local charset = res.charset or "utf-8"
                local headers = res._headers
                headers["Content-Type"]         = mime .. ";charset=" .. charset
                headers["Content-Length"]       = #output
                setHeaders(headers)

                local ok, err = ngx.say(output)
                if not ok then
                        res.status      = ngx.HTTP_INTERNAL_SERVER_ERROR
                        res.error       = err
                        return false
                end
        else
                setHeaders(res._headers)
        end

        return true
end

function _M.json(res)
        local input = res._input
        local inputType = type(input)
        local output
        if inputType == "string" then
                output = input
        elseif inputType == "table" then
                local out, err = cjson.encode(input)
                if out then
                        output = out
                else
                        error("Response:json(input) json encode error: " .. err)
                end
        else
                error("Response:json(input) input must be string or table")
        end

        local mime = res.type or MIME.JSON
        local charset = res.charset or "utf-8"
        local headers = res._headers
        headers["Content-Type"]         = mime .. ";charset=" .. charset
        headers["Content-Length"]       = #output
        setHeaders(headers)
        cookie.set(res._cookies)

        local ok, err = ngx.say(output)
        if not ok then
                res.status      = ngx.HTTP_INTERNAL_SERVER_ERROR
                res.error       = err
                return false
        end

        return true
end

function _M.xml(res)
        local input = res._input
        local inputType = type(input)
        local output
        if inputType == "string" then
                output = input
        elseif inputType == "table" then
                output = xml.encode(input)
        else
                error("Response:xml(input) input must be string or table")
        end

        local mime = res.type or MIME.XML
        local charset = res.charset or "utf-8"
        local headers = res._headers
        headers["Content-Type"]         = mime .. ";charset=" .. charset
        headers["Content-Length"]       = #output
        setHeaders(headers)
        cookie.set(res._cookies)

        local ok, err = ngx.say(output)
        if not ok then
                res.status      = ngx.HTTP_INTERNAL_SERVER_ERROR
                res.error       = err
                return false
        end

        return true
end

local JSONP_CALLBACK = "[]$."
local JSONP_CALLBACK_REGEXP = "[^%w" .. 
                              utils.encodeLuaMagic(URI_RESERVED) .. 
                              "]"

function _M.jsonp(res)
        local input = res._input
        local inputType = type(input)
        local output
        if inputType == "string" then
                output = input
        elseif inputType == "table" then
                local out, err = cjson.encode(input)
                if out then
                        output = out
                else
                        error("Response:jsonp(input) json encode error: " .. err)
                end
        else
                error("Response:jsonp(input) input must be string or table")
        end

        local mime
        local callback = res._callback
        local headers = res._headers
        local charset = res.charset or "utf-8"
        if type(callback) == "string" and #callback > 0 then
                callback = string.gsub(callback, JSONP_CALLBACK_REGEXP, "")
                output = "/**/ typeof " .. callback .. " === 'function' && " .. callback .. "(" .. output .. ")"
                mime = res.type or MIME.JSONP
        else
                mime = res.type or MIME.JSON
        end

        headers["X-Content-Type-Options"]       = "nosniff"
        headers["Content-Type"]                 = mime .. ";charset=" .. charset
        headers["Content-Length"]               = #output
        setHeaders(headers)
        cookie.set(res._cookies)

        local ok, err = ngx.say(output)
        if not ok then
                res.status      = ngx.HTTP_INTERNAL_SERVER_ERROR
                res.error       = err
                return false
        end

        return true
end

return _M
