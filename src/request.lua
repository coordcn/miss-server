-- Copyright © 2017 coord.cn. All rights reserved.
-- @author      QianYe(coordcn@163.com)
-- @license     MIT license

local cjson     = require("cjson.safe")

local core      = require("miss-core")
local Object    = core.Object
local MIME      = core.MIME
local xml       = core.xml
local cookie    = core.cookie

local validator = require("miss-validator")
local verify    = validator.verify

local Request   = Object:extend()

function Request:constructor(input)
        self.options            = input.options
        self.method             = input.method
        self.uri                = input.uri
        self.path               = input.path
        -- path params
        self.params             = input.params
        self.type               = input.type
        self.length             = input.length
        self.charset            = input.charset
        self.scheme             = ngx.var.scheme
        self.host               = ngx.var.host
        self.cookie             = ngx.var.http_cookie
        self.referer            = ngx.var.http_referer
        self.refer              = self.referer 
        self.userAgent          = ngx.var.http_user_agent
        self.ip                 = ngx.var.remote_addr
        self.ips                = ngx.var.http_x_forwarded_for
end

function Request:getSocket()
        if self._socket_got then
                return self._socket, self._socker_err
        else
                local socket, err = ngx.req.socket()
                self._socket = socket
                self._socket_err = err
                self._socket_got = true
                return socket, err
        end
end

function Request:getHeaders()
        if self._headers then
                return self._headers
        else
                local headers = ngx.req.get_headers()
                self._headers = headers
                return headers
        end
end

function Request:getHeader(name)
        local tmp

        if self._headers then
                tmp = self._headers[name]
        else
                local headers = ngx.req.get_headers()
                self._headers = headers
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
                        local body = ngx.req.get_body_data()
                        self._body = body
                        self._body_got = true
                        return body
                else
                        self._body_got = true
                end
        end
end

-- @brief       get and verify path params
--              /api/v1/:name/:article
--              /api/v1/abc/lol
--              {
--                      name = "abc",
--                      article = "lol",
--              }
-- @param       args    {object|required}        
function Request:getParams(args)
        if self._params_got then
                return self._params, self._params_err
        else
                local params, err = verify(self._params, args)
                self._params = params
                self._params_err = err
                self._params_got = true
                return params, err
        end
end

function Request:getQuery(args)
        if self._query_got then
                return self._query, self._query_err
        else
                local _query = ngx.req.get_uri_args()
                local  query, err = verify(_query, args)
                self._query = query
                self._query_err = err
                self._query_got = true
                return query, err
        end
end

function Request:getJSON(args)
        if self._json_got then
                return self._json, self._json_err
        else
                if self.length and 
                   self.length > 0 and
                   self.type == MIME.JSON then
                        local body = self:getBody()
                        if body then
                                local _json, _err = cjson.decode(body)
                                if _json then
                                        local json, err = verify(_json, args)
                                        self._json = json
                                        self._json_err = err
                                        self._json_got = true
                                        return json, err
                                else
                                        self._json_got = true
                                        self._json_err = _err
                                        return nil, _err
                                end
                        end
                end

                self._json_got = true
        end
end

function Request:getXML(args)
        if self._xml_got then
                return self._xml, self._xml_err
        else
                if self.length and 
                   self.length > 0 and
                   self.type == MIME.TEXT_XML or
                   self.type == MIME.XML then
                        local body = self:getBody()
                        if body then
                                local _xml = xml.decode(body)
                                local xml_, err = verify(_xml, args)
                                self._xml = xml_
                                self._xml_err = err
                                self._xml_got = true
                                return xml_, err
                        end
                end

                self._xml_got = true
        end
end

function Request:getForm(args)
        if self._form_got then
                return self._form, self._form_err
        else
                ngx.req.read_body()
                local _form, _err = ngx.req.get_post_args()
                if _err then
                        self._form_err = _err
                        self._form_got = true
                        return nil, _err
                end

                local form, err = verify(_form, args)
                self._form = form
                self._form_err = err
                self._form_got = true
                return form, err
        end
end

function Request:getCookies()
        if self._cookies_got then
                return self._cookies
        else
                local cookies = cookie.decode(self.cookie)
                self._cookies = cookies
                self._cookies_got = true
                return cookies
        end
end

function Request:getCookie(name)
        if self._cookies_got then
                return self._cookies[name]
        else
                local cookies = cookie.decode(self.cookie)
                self._cookies = cookies
                self._cookies_got = true
                return cookies[name]
        end
end

return Request
