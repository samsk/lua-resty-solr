-- solr.args module
local _M = {}
local mt = {
	__index = _M,
}

local string_sub = string.sub
local table_insert = table.insert
local table_concat = table.concat

local cjson_flat = require("cjson").decode_max_depth(1)
local http_args = require "resty.solr.http.args"

local function _deepcopy(obj, seen)
	if type(obj) ~= 'table' then
		return obj
	end

	if seen and seen[obj] then
		return seen[obj]
	end

	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))

	s[obj] = res
	for k, v in pairs(obj) do
		res[_deepcopy(k, s)] = _deepcopy(v, s)
	end

	return res
end

local function _escape_str(str)
	return str
end

function _M.new(_opts)
	local object = {}
	_M.reset(object)
	return setmetatable(object, mt)
end

function _M:reset()
	self.args = {
		fq = {},
		wt = 'xml',
	}
	return self
end

----
-- generic argument
function _M:arg(arg, value, def)
	if value ~= nil then
		self.args[arg] = value
	elseif def ~= nil then
		self.args[arg] = def
	end
	return self
end

----
-- generic numeric argument
function _M:arg_number(arg, value, def)
	if tonumber(value) ~= nil then
		self.args[arg] = value
	elseif def ~= nil then
		self.args[arg] = def
	end
	return self
end

----
-- query_param
function _M:query_param(param)
	self.arg_q = param
	return self
end


----
-- df=
function _M:query_field(field)
	return self:arg('df', field)
end

----
-- fl=
function _M:result_field(field)
	return self:arg('fl', field)
end

----
-- q=
function _M:query(arg, value, def)
	if value ~= nil and value ~= '' then
		if arg ~= nil then
			self.args[arg] = value
		end
		return self:arg(self.arg_q, value, def)
	elseif def ~= nil then
		return self:arg(self.arg_q, value, def)
	end
	return self
end

----
-- q=
function _M:any_query(arg, value, def)
	if arg ~= nil then
		self.args[arg] = value
	end
	return self:arg(self.arg_q, value, def)
end

----
-- q=*
function _M:wildcard_query(arg, value, wildprefix)
	if value ~= nil then
		if arg ~= nil then
			self.args[arg] = value
		end
		if wildprefix ~= nil and wildprefix then
			value = '*' .. value
		end
		value = value .. '*'
	end
	return self:arg(self.arg_q, value)
end

----
-- q=*
function _M:quoted_query(arg, value)
	if value ~= nil then
		if arg ~= nil then
			self.args[arg] = value
		end
		value = '"' .. _escape_str(value) .. '"'
	end
	return self:arg(self.arg_q, value)
end

----
-- q=field:*
function _M:field_query(arg, field, value)
	if value ~= nil then
		if arg ~= nil then
			self.args[arg] = value
		end
		value = field .. ':"' .. _escape_str(value) .. '"'
	end
	return self:arg(self.arg_q, value)
end

----
-- start=
function _M:start(value)
	return self:arg_number('start', value, 0)
end

----
-- rows=
function _M:rows(value)
	return self:arg_number('rows', value)
end

----
-- pager=
function _M:pager(value)
	return self:arg('pager', value)
end

----
-- sort=
function _M:sort(arg, mode, value)
	self:arg(arg, mode)
	return self:arg('sort', value)
end

----
local function _build_filter(fq, value, cb, op)
	local retval_filter
	local retval_arg
	local value_arg_complex = 0

	if value ~= nil and value ~= '' then
		if type(value) ~= "table" then
			value = { value }
		end

		local value_arg = {}

		if cb ~= nil then
			for k,v in pairs(value) do
				if string_sub(v, 1, 2) == '["'
						and string_sub(v, -2) == '"]' then
					-- THROWS error, if not flat (should we catch it ?)
					local v_table = cjson_flat.decode(v)

					if v_table ~= nil and type(v_table) == "table" then
						table_insert(value_arg, _deepcopy(v_table))
						value_arg_complex = 1

						for nk,nv in pairs(v_table) do
							v_table[nk] = cb(nv)
						end

						v = '(' .. table_concat(v_table, ' AND ') .. ')'
					else
						table_insert(value_arg, v)
						v = cb(v)
					end
				else
					table_insert(value_arg, v)
					v = cb(v)
				end

				value[k] = v
			end
		else
			value_arg = value
		end

		local glue = ' '
		if op ~= nil then
			glue = ' ' .. op .. ' '
		end

		if value_arg_complex == 1 then
			retval_arg = cjson_flat.encode(value_arg)
		else
			retval_arg = table_concat(value_arg, ',')
		end

		retval_filter = fq .. ':(' .. table_concat(value, glue) .. ')'

	end
	return retval_filter, retval_arg, value_arg_complex
end

----
-- fq=
function _M:filter_multi_raw(arg, args, op)
	local filters = {}

	for _,v in pairs(args) do
		local filter, argv, is_complex = _build_filter(v.fq, v.value, v.cb, v.op)

		if is_complex == 1 then
			self.args['json:' .. v.arg] = argv
		else
			self.args[v.arg] = argv
		end

		table_insert(filters, filter)
	end

	if #filters > 0 then
		local glue = ' AND '
		if op ~= nil then
			glue = ' ' .. op .. ' '
		end

		self.args['fq'][arg] = table_concat(filters, glue)
	end
	return self
end

----
-- fq=
function _M:filter_raw(arg, fq, value, cb, op)
	local filter, argv, is_complex = _build_filter(fq, value, cb, op)

	if filter ~= nil then
		if is_complex == 1 then
			self.args['json:' .. arg] = argv
		else
			self.args[arg] = argv
		end
		self.args['fq'][arg] = filter
	end
	return self
end

----
-- fq=
function _M:filter_raw_and(arg, fq, value, cb)
	return self.filter_raw(arg, fq, value, cb, 'AND')
end

----
-- fq=
function _M:filter(arg, fq, value)
	return self:filter_raw(arg, fq, value, function(v) return v end)
end

----
-- fq=*
function _M:filter_range(arg, fq, valueFrom, valueTo, options)
	local filter = nil
	local lowerBound = '['
	local upperBound = ']'

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
			self.args['argr_' .. arg] = valueFrom .. ':' .. valueTo
			filter = fq .. ':' .. lowerBound .. valueFrom
						.. ' TO ' .. valueTo .. upperBound
		end
	end

	if options ~= nil and options.withNull ~= nil and options.withNull == 1 then
		local filterNull = '*:* AND -' .. fq .. ':*'

		self.args['arg_' .. arg .. 'IsNull'] = options.withNull
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
function _M:filter_bool(arg, fq, value)
	if value ~= nil and (value == 1 or value == '1') then
		return self:filter_raw('arg_' .. arg, fq, 1)
	elseif value == 0 or value == '0' then
		return self:filter_raw('arg_' .. arg, fq, 0)
	end
	return self
end

----
-- fq=
function _M:filter_datetime_from(arg, fq, value)
	if value ~= nil and value ~= '' then
		self.args[arg] = value
		self.args['fq'][arg] = fq .. ':' .. '[' .. value .. ' TO NOW]'
	end
	return self
end

----
-- fq=
function _M:filter_date_from(arg, fq, value)
	if value ~= nil and value ~= '' then
		self.args[arg] = value
		self.args['fq'][arg] = fq .. ':' .. '[' .. value .. 'T00:00:00Z TO NOW]'
	end
	return self
end

----
-- fq=
function _M:filter_day_from(arg, fq, value)
	if value ~= nil and value ~= '' then
		self.args[arg] = value
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
			self.args[arg] = valueFrom .. ':' .. valueTo
			self.args['fq'][arg] = fq .. ':[' .. valueFrom .. ' TO ' .. valueTo .. ']'
		end
	end
	return self
end

----
-- fq=
function _M:filter_hour_from(arg, fq, value)
	if value ~= nil and value ~= '' then
		self.args[arg] = value
		self.args['fq'][arg] = fq .. ':' .. '[NOW-' .. value .. 'HOUR TO NOW]'
	end
	return self
end

----
-- wt=
function _M:output(out)
	self.args['wt'] = out
	return self
end

----
-- wt=xml
function _M:output_json(enabled)
	if enabled then
		self.args['wt'] = 'xml'
	end
	return self
end

----
-- wt=json
function _M:output_json(enabled)
	if enabled then
		self.args['wt'] = 'json'
		self.args['omitHeader'] = 'on'	-- true?
	end
	return self
end

----
-- build final arg string
function _M:build()
	local args = {}
	local webargs = http_args.new()

	for key, val in pairs(self.args) do
		if key == 'fqX' and type(val) == 'table' then
			local vals = {}

			for _, val1 in pairs(val) do
				table_insert(vals, '(' .. val1 .. ')')
			end
			webargs.add(args, key, table_concat(vals, ' AND '))
		elseif type(val) == 'table' then
			for _, val1 in pairs(val) do
				webargs.add(args, key, val1)
			end
		else
			webargs.add(args, key, val)
		end
	end
	return webargs.build(args)
end

return _M
