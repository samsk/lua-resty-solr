-- solr.json_api module
local _M = {}
local mt = {
	__index = _M,
}

local cjson = require("cjson")

function _M.new(data)
	local object = {
		data = data or {}
	}
	return setmetatable(object, mt)
end

function _M:set(key, value)
	self.data['json.' .. key] = value
end

function _M:build()
	return cjson.encode(self.data)
end

function _M:set_body()
	local ngx = require("ngx")

	ngx.set_body_data(self:build())
end

return _M
