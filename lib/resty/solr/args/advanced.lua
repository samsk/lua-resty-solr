-- solr.args.advanced module
local _M = {}

local solr_args = require "resty.solr.args"
local solr_sort = require "resty.solr.sort"

local mt = setmetatable(_M, { __index = solr_args })
mt.__index = _M

local ARG_NORM  = 'arg_'
local ARG_BOOL = 'argb_'
local ARG_RANGE = 'argr_'
local ARG_MULTI = 'args_'
local ARG_ISNULL = 'IsNull'
local ARG_GEOM = 'argg_'
local ARG_POLYGON = 'argp_'

-- pass value callback
local function _pass(v)
    return v
end

-- quote string value callback (with support for negative)
local function _exact(v)
    if string.sub(v, 1, 1) == '!' then
        return 'NOT "' .. string.sub(v, 2) .. '"'
    else
        return '"' .. v .. '"'
    end
end

-- append wildcard to string value callback
local function _wildcard(v)
    return '*' .. v .. '*'
end

-- match simple string map (VALUE1:[VALUE2])
local function _exact_map(v)
    if string.match(v, "^%w+$") then
            return v .. '\\:' .. '*'
    else
            return '"' .. v .. '"'
    end
end

-- match wildcard map ([VALUE1]:[VALUE2])
local function _wildcard_map(v)
    return string.gsub(string.gsub(string.gsub(string.gsub(v,
                ':NULL', ':*')
                    , 'NULL:', '*:')
                        , ':', '\\:')
                            , ' ', '\\ ')
end

-- match polygon
local function _polygon(v)
    return '"Intersects(POLYGON((' .. v .. ')))"'
end

-- match int number
local function _intnumber(v)
    -- return tonumber(v) | 0      -- force integer, alternative to math.tointeger
    return math.floor(tonumber(v))
end

-- match float number
local function _floatnumber(v)
    return tonumber(v) + 0.0
end

--- create new object
-- @param opts - options
-- @param opts.sort - sort options (see solr.sort)
function _M.new(opts)
	local object = solr_args.new()

	local sort_fields = {}
	local sort_opts = {}
	if opts ~= nil then
		if opts.sort ~= nil then
			sort_fields = opts.sort.fields or {}
			sort_config = opts.sort.opts or {}
		end
	end
	object.sort = solr_sort.new(sort_fields, sort_opts)
	return setmetatable(object, mt)
end

----
-- fq=
function _M:filter(arg, fq, value)
	return self:filter_raw(ARG_NORM .. arg, fq, value, _pass)
end

----
-- fq=
function _M:filter_string(arg, fq, value)
	return self:filter_raw(ARG_NORM .. arg, fq, value, _exact)
end

----
-- fq=
function _M:filter_string_like(arg, fq, value)
	return self:filter_raw(ARG_NORM .. arg, fq, value, _wildcard)
end

----
-- fq=
function _M:filter_number(arg, fq, value)
	return self:filter_raw(ARG_NORM .. arg, fq, value, tonumber)
end

----
-- fq=
function _M:filter_integer(arg, fq, value)
	return self:filter_raw(ARG_NORM .. arg, fq, value, _intnumber)
end

----
-- fq=
function _M:filter_float(arg, fq, value)
	return self:filter_raw(ARG_NORM .. arg, fq, value, _floatnumber)
end

----
-- fq=
function _M:filter_string_map(arg, fq, value)
	return self:filter_raw(ARG_NORM .. arg, fq, value, _exact_map)
end

----
-- fq=
function _M:filter_string_any_map(arg, fq, value)
	return self:filter_raw(ARG_NORM .. arg, fq, value, _wildcard_map)
end

----
-- fq=
function _M:filter_polygon(arg, fq, value)
	return self:filter_raw(ARG_POLYGON .. arg, fq, value, _polygon)
end

----
-- fq=*
function _M:filter_any_range(arg, fq, valueFrom, valueTo, options, cb)
	local filter = nil
	local lowerBound = '['
	local upperBound = ']'
	local argPrefix = (options ~= nil and options.argPrefix) or ARG_RANGE

	if cb ~= nil then
		if valueFrom ~= nil then
			valueFrom = cb(valueFrom)
		end
		if valueTo ~= nil then
			valueTo = cb(valueTo)
		end
	end

	if options ~= nil and options.lowerExclusive ~= nil
				and options.lowerExclusive == 1 then
		lowerBound = '{'
	end
	if options ~= nil and options.upperExclusive ~= nil
				and options.upperExclusive == 1 then
		upperBound = '}'
	end

	if (valueFrom ~= nil or valueTo ~= nil) then
		if valueFrom == nil or valueFrom == '' then
			valueFrom = '*'
		end
		if valueTo == nil or valueTo == '' then
			valueTo = '*'
		end

		if valueTo ~= '*' or valueFrom ~= '*' then
			self.args[argPrefix .. arg] = valueFrom .. ':' .. valueTo
			filter = fq .. ':' .. lowerBound .. valueFrom
						.. ' TO ' .. valueTo .. upperBound
		end
	end

	if options ~= nil and options.withNull ~= nil and options.withNull == 1 then
		local filterNull = '*:* AND -' .. fq .. ':*'

		self.args[ARG_ISNULL .. arg .. ARG_ISNULL] = options.withNull
		if filter ~= nil then
			filter = '((' .. filterNull .. ') OR (' .. filter .. '))'
		else
			filter = filterNull
		end
	end

	if filter ~= nil then
		self.args['fq'][arg] = filter
	end

	return self
end

----
-- fq=
function _M:filter_int_range(arg, fq, valueFrom, valueTo, options)
	return self:filter_any_range(arg, fq, valueFrom, valueTo, options,
					_intnumber)
end

----
-- fq=
function _M:filter_float_range(arg, fq, valueFrom, valueTo, options)
	return self:filter_any_range(arg, fq, valueFrom, valueTo, options,
					_floatnumber)
end

----
-- fq=
function _M:filter_boundary(arg, fq, valueFrom, valueTo, options)
	options = options or {}
	options.argPrefix = ARG_GEOM
	return self:filter_any_range(arg, fq, valueFrom, valueTo, options,
					_floatnumber)
end

----
-- fq=
function _M:filter_bool(arg, fq, value)
	if value ~= nil and value == 1 then
		return self:filter_raw(ARG_BOOL .. arg, fq, 1)
	elseif value == 0 then
		return self:filter_raw(ARG_BOOL .. arg, fq, 0)
	end
	return self
end

----
-- fq=
function _M:filter_datetime_from(arg, fq, value)
	if value ~= nil and value ~= '' then
		self.args[ARG_NORM .. arg] = value
		self.args['fq'][arg] = fq .. ':' .. '[' .. value .. ' TO NOW]'
	end
	return self
end

----
-- fq=
function _M:filter_date_from(arg, fq, value)
	if value ~= nil and value ~= '' then
		self.args[ARG_NORM .. arg] = value
		self.args['fq'][arg] = fq .. ':' .. '[' .. value .. 'T00:00:00Z TO NOW]'
	end
	return self
end

----
-- fq=
function _M:filter_day_from(arg, fq, value)
	if value ~= nil and value ~= '' then
		self.args[ARG_NORM .. arg] = value
		self.args['fq'][arg] = fq .. ':' .. '[NOW-' .. value .. 'DAY TO NOW]'
	end
	return self
end

function _M:filter_day_range(arg, fq, valueTo, valueFrom)
	if (valueFrom ~= nil or valueTo ~= nil) then
		if valueFrom == nil or valueFrom == '' then
			valueFrom = '*'
		else
			valueFrom = 'NOW-' .. valueFrom .. 'DAY'
		end
		if valueTo == nil or valueTo == '' then
			valueTo = '*'
		else
			valueTo = 'NOW-' .. valueTo .. 'DAY'
		end

		if valueTo ~= '*' or valueFrom ~= '*' then
			self.args[ARG_RANGE .. arg] = valueFrom .. ':' .. valueTo
			self.args['fq'][arg] = fq .. ':[' .. valueFrom .. ' TO ' .. valueTo .. ']'
		end
	end
	return self
end

----
-- fq=
function _M:filter_hour_from(arg, fq, value)
	if value ~= nil and value ~= '' then
		self.args[ARG_NORM .. arg] = value
		self.args['fq'][arg] = fq .. ':' .. '[NOW-' .. value .. 'HOUR TO NOW]'
	end
	return self
end

-- override sort_by
function _M:sort_by(value)
	local sort, sort_fields = self.sort:build(value)
	return self:sort_string('sort', sort, sort_fields)
end

-- sort by string expression
function _M:sort_string(arg, value, arg_value)
	self.args[ARG_MULTI .. arg] = arg_value or value
	return solr_args.sort_by(self, value)
end

return _M
