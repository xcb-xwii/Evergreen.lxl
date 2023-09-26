local core = require 'core'
local languages = require 'plugins.evergreen.languages'

local M = {}

local cache = {}

local function localPath()
	local str = debug.getinfo(2, 'S').source:sub(2)
	return str:match '(.*[/\\])'
end

function M.get(ftype, qtype)
	if not cache[ftype] then
		cache[ftype] = {}
	end

	if cache[ftype][qtype] then
		return cache[ftype][qtype]
	end

	local ff = io.open(string.format(
		'%s/queries/%s/%s.scm',
		localPath(),
		ftype,
		qtype
	))
	if not ff then
		core.warn(string.format(
			'Could not find the %s query for language \'%s\'. ' ..
			'Evergreen may not work as expected.',
			qtype,
			ftype
		))
		return ''
	end

	local head = ff:read '*l'
	local queryList = {}
	if head:sub(1, 12) == '; inherits: ' then
		for s in head:sub(13):gmatch '[%l_]+' do
			table.insert(queryList, M.get(s, qtype))
		end
	end
	
	ff:seek('set', 0)
	table.insert(queryList, ff:read '*a')
	ff:close()

	local query = table.concat(queryList)
	cache[ftype][qtype] = query

	return query
end

function M.highlights(ftype)
	return M.get(ftype, 'highlights')
end

function M.injections(ftype)
	return M.get(ftype, 'injections')
end

return M
