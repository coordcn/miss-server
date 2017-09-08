-- Copyright © 2017 coord.cn. All rights reserved.
-- @author      QianYe(coordcn@163.com)
-- @license     MIT license

local cjson     = require("cjson.safe")
local core      = require("miss-core")
local Object    = core.Object
local MIME      = core.MIME
local xml       = core.xml
local cookie    = core.cookie
local upload    = core.upload

local validator = require("miss-validator")
local verify    = validator.verify

local ERR_NO_BODY   = "no body"
local ERR_NOT_JSON  = "content type is not " .. MIME.JSON
local ERR_NOT_XML   = "content type is not " .. MIME.XML .. " or " .. MIME.TEXT_XML
local ERR_NOT_FORM  = "content type is not " .. MIME.FORM .. " or " .. MIME.MULTIPART


local Request   = Object:extend()

function Request:constructor(input)
    self.options    = input.options
    self.method     = input.method
    self.uri        = input.uri
    self.path       = input.path
    -- path params
    self.params     = input.params
    self.type       = input.type
    self.length     = input.length
    self.charset    = input.charset
    self.headers    = input.headers

    self.scheme     = ngx.var.scheme
    self.host       = ngx.var.host
    self.cookie     = ngx.var.http_cookie
    self.referer    = ngx.var.http_referer
    self.refer      = self.referer 
    self.userAgent  = ngx.var.http_user_agent
    self.ip         = ngx.var.remote_addr
    self.ips        = ngx.var.http_x_forwarded_for
end

function Request:getSocket()
    if self._socket_got then
        return self._socket_err, self._socker
    else
        local socket, err = ngx.req.socket()
        self._socket        = socket
        self._socket_err    = err
        self._socket_got    = true
        return err, socket
    end
end

function Request:getHeaders()
    if self.headers then
        return self.headers
    else
        local headers   = ngx.req.get_headers()
        self.headers    = headers
        return headers
    end
end

function Request:getHeader(name)
    local tmp

    if self.headers then
        tmp = self.headers[name]
    else
        local headers   = ngx.req.get_headers()
        self.headers    = headers
        tmp = headers[name]
    end

    if type(tmp) == "table" then
        return tmp[1]
    else
        return tmp
    end
end

function Request:getBody()
    if self._body_got then
        return self._body
    else
        if self.length and self.length > 0 then
            ngx.req.read_body()
            local body      = ngx.req.get_body_data()
            self._body      = body
            self._body_got  = true
            return body
        end
        self._body_got = true
    end
end

-- @brief   get and verify path params
--          /api/v1/:name/:article
--          /api/v1/abc/lol
--          {
--                  name = "abc",
--                  article = "lol",
--          }
-- @param   args    {object|required}
-- @return  err     {string}
-- @return  params  {object}
function Request:getParams(args)
    if self._params_got then
        return self._params_err, self._params
    else
        local err, params = verify(self._params, args)
        self._params        = params
        self._params_err    = err
        self._params_got    = true
        return err, params
    end
end

function Request:getQuery(args)
    if self._query_got then
        return self._query_err, self._query
    else
        local _query = ngx.req.get_uri_args(self.options.maxArgCount)
        local  err, query = verify(_query, args)
        self._query     = query
        self._query_err = err
        self._query_got = true
        return err, query
    end
end

function Request:getJSON(args)
    if self._json_got then
        return self._json_err, self._json
    else
        if self.type == MIME.JSON then
            local body = self:getBody()
            if body then
                local _json, _err = cjson.decode(body)
                if _json then
                    local err, json = verify(_json, args)
                    self._json      = json
                    self._json_err  = err
                    self._json_got  = true
                    return err, json
                else
                    self._json_got  = true
                    self._json_err  = _err
                    return _err
                end
            else
                self._json_got  = true
                self._json_err  = ERR_NO_BODY
                return ERR_NO_BODY
            end
        else
            self._json_got  = true
            self._json_err  = ERR_NOT_JSON
            return ERR_NOT_JSON
        end
    end
end

function Request:getXML(args)
    if self._xml_got then
        return self._xml_err, self._xml
    else
        if self.type == MIME.TEXT_XML or
           self.type == MIME.XML then
            local body = self:getBody()
            if body then
                local _xml      = xml.decode(body)
                local err, xml_ = verify(_xml, args)
                self._xml       = xml_
                self._xml_err   = err
                self._xml_got   = true
                return err, xml_
            else
                self._xml_got   = true
                self._xml_err   = ERR_NO_BODY
                return ERR_NO_BODY
            end
        else
            self._xml_got   = true
            self._xml_err   = ERR_NOT_XML
            return ERR_NOT_XML
        end
    end
end

function Request:getForm(args)
    if self._form_got then
        return self._form_err, self._form_query, self._form_files
    else
        if self.type == MIME.FORM then
            ngx.req.read_body()
            local _query, _err = ngx.req.get_post_args(self.options.maxArgCount)
            if _err then
                self._form_err  = _err
                self._form_got  = true
                return _err
            end

            local err, query    = verify(_query, args)
            self._form_query    = query
            self._form_err      = err
            self._form_got      = true
            return err, query
        elseif self.type == MIME.MULTIPART then
            local _err, _query, files = upload.handle(self.options)
            if _err then
                self._form_err  = _err
                self._form_got  = true
                return _err
            end

            local err, query    = verify(_query, args)
            self._form_query    = query
            self._form_files    = files
            self._form_err      = err
            self._form_got      = true
            return err, query, files
        else
            self._form_got  = true
            self._form_err  = ERR_NOT_FORM
            return ERR_NOT_FORM
        end
    end
end

function Request:getCookies()
    if self._cookies_got then
        return self._cookies
    else
        local cookies       = cookie.decode(self.cookie)
        self._cookies       = cookies
        self._cookies_got   = true
        return cookies
    end
end

function Request:getCookie(name)
    if self._cookies_got then
        return self._cookies[name]
    else
        local cookies       = cookie.decode(self.cookie)
        self._cookies       = cookies
        self._cookies_got   = true
        return cookies[name]
    end
end

return Request
