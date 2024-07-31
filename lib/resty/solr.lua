-- solr.get module
local _M = {
	version = "0.2",
}
local mt = {
	__index = _M,
}

setmetatable(_M, {
	__call = function (cls, ...)
		local self = setmetatable({}, cls)
		self:_init(...)
	        return self
        end,
})

local ngx = require "ngx"

local ngx_req = ngx.req
local ngx_location_capture = ngx.location.capture

local string_len = string.len
local string_sub = string.sub
local string_gsub = string.gsub

---- New SOLR object
--
function _M.new(_self, _opts)
	return setmetatable({}, mt)
end

--- Get one record from solr url
-- @param location
-- @param solr_args
-- @param field
-- @param chomp
function _M.get_one(location, solr_args, field, chomp)
	ngx_req.read_body();
	local resp = ngx_location_capture(location,
			{ args = solr_args
					.result_field(field)
					.output('csv')
					.rows(1)
					.build() })
	local body = resp.body or ''

	local data = nil
	local field_len = string_len(field)
	if body ~= nil and string_sub(body, 1, field_len) == field then
		data = string_sub(body, field_len + 2)

		if chomp ~= nil then
			data = string_gsub(data, "\n$", "") -- chomp
		end
	end

	return data
end

return _M
