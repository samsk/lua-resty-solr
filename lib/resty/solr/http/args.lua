-- solr.http.args module
local _M = {}
local mt = {
	__index = _M,
}

local cjson = require("cjson");

local table_insert = table.insert
local table_concat = table.concat
local string_gsub = string.gsub

function _M.new(_self, args)
	return setmetatable({
		http_args = args or {},
	}, mt)
end

function _M.format(key, val)
	return key .. '=' .. val
end

function _M:add_str(str)
	table_insert(self.http_args, str);
end

function _M:add(key, val, defval)
	if val == nil and defval ~= nil then
		val = defval
	end
	if val ~= nil then
		self:add_str(_M.format(key, val))
	end
end

function _M:add_json(key, val)
	self:add_str(_M.format(key, cjson.encode(val)))
end

function _M:add_array(arr)
	for i = 0, #arr, 1 do
		self:add_str(arr[i])
	end
end

function _M:build()
	return string_gsub(table_concat(self.http_args, '&'), ' ', '%%20')
end

return _M
