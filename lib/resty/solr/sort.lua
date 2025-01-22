-- solr.args module
local _M = {}
local mt = {
	__index = _M,
}

local string_sub = string.sub
local table_insert = table.insert
local table_concat = table.concat

local sort_mode = {
        ['+'] = 'ASC',
        ['-'] = 'DESC',
}

--- get last character of a string
local function lastChar(str)
        return string_sub(str, -1)
end

--- Create new sort object
-- @param sortables - list of sortable fields
-- @param opts - options
-- @param opts.default - default sort
-- @param opts.default_mode - default sort mode (+/-)
-- @param opts.map - map of sort values to sort fields
--                     (ie. neweset = timestamp+, oldest = timestamp-)
-- @return sort object
function _M.new(sortables, opts)
	local object = {
		fields = {},
		map = opts.map,
		default = opts.default,
		default_mode = opts.default_mode,
	}

	for _, field in pairs(sortables or {}) do
		object.fields[field] = 1
	 end
	return setmetatable(object, mt)
end

--- Build sort string and fields
-- @param arg - sort string argument, can be a string or a table
--                      ie. {'timestamp+', 'timestamp-', 'oldest'}
-- @return sort string for SOLR and fields that were sortable
function _M:build(arg)
	local values = arg

	if values == nil then
		values = self.default
	end
	if type(values) ~= 'table' then
		values = { values }
	end

	local sort_str = {}
	local sort_fields = {}
	for _, val in pairs(values) do
		-- try to find a mapping
		if self.map ~= nil and self.map[val] ~= nil then
			val = self.map[val]
		end

		-- try to find a mod (ASC+, DESC-)
		local mod = lastChar(val)
		if mod == '-' or mod == '+' then
			val = string_sub(val, 1, -2)
		else
			mod = self.default_mode
		end

		if self.fields[val] ~= nil then
			if sort_mode[mod] ~= nil then
				val = val .. ' ' .. sort_mode[mod]
			end
			table_insert(sort_str, val)
		end
	end
	return table_concat(sort_str, ','), sort_fields
end

return _M
