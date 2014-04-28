-- The MIT License (MIT)
--
-- Copyright (c) 2014 Cyril David <cyx@cyx.is>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

local format = string.format
local sub    = string.sub

local CODEX = {
	['{%'] = function(code)
		return code
	end,

	['{{'] = function(code)
		return format('__o[#__o+1] = %s', code)
	end
}

local function parse(tmpl, locals)
	-- matches an empty block %b{} in our gmatch below
	local tmpl = tmpl .. '{}'

	-- `compile` returns a function which accepts a table
	local code = {
		'return function(params) \n local __o = {}'
	}

	-- In order to facilitate local variables, we compile in
	-- the list of allowed local variables for a given template, e.g.
	--
	-- Given:
	--     locals = { 'user', 'post' }
	--
	-- Result:
	--     local user = params["user']
	--     local post = params["post']
	--
	for _, var in ipairs(locals) do
		code[#code+1] = format('local %s = params["%s"]', var, var)
	end

	-- Split the entire template by text + block pairs.
	--
	-- - block => string enclosed by matching `{ }`
	-- - text => anything not beginning with a `{`.
	--
	for text, block in string.gmatch(tmpl, "([^{]-)(%b{})") do
		-- operations are defined in our CODEX table.
		local op = CODEX[sub(block, 1, 2)]

		-- case 1: append the text, apply the op
		if op then
			code[#code+1] = format('__o[#__o+1] = [[%s]]', text)
			code[#code+1] = op(sub(block, 3, -3))
		-- case 2: no operation, so we did a false positive match
		elseif #block > 2 then
			code[#code+1] = format('__o[#__o+1] = [[%s%s]]', text, block)
		-- case 3: we matched the sentinel value `{}` we pushed above.
		else
			code[#code+1] = format('__o[#__o+1] = [[%s]]', text)
		end
	end

	-- Our return function returns the concatenation of all strings.
	code[#code+1] = 'return table.concat(__o) \n end'

	-- Our resultant code
	return table.concat(code, '\n')
end

local function compile(name, tmpl, locals)
	local code = parse(tmpl, locals)

	---- Throw an error if there's a parse error in the generated code.
	local f = assert(loadstring(code, name))

	---- Return the anonymous function we just created.
	return f()
end

local function read(path)
	local file = assert(io.open(path, "r"))
	local data = file:read("*all")

	file:close()

	return data
end

local CACHE = {}

return function(filename, params)
	if not CACHE[filename] then
		local keys = {}

		for k, _ in pairs(params) do
			keys[#keys+1] = k
		end

		CACHE[filename] = compile(filename, read(filename), keys)
	end

	return CACHE[filename](params)
end
