
------------------------------------
-- Loading disscetors
------------------------------------

require("ipv4")
require("tcp")
require("http")


haka.rule {
	hooks = {"tcp-connection-new"},
	eval = function (self, pkt)

		if pkt.tcp.dstport == 8888 then
			pkt.next_dissector = "http"
		end
	end
}


------------------------------------
-- Req./Resp Transform Operations
------------------------------------

function percent_decode(uri)
	uri = string.gsub (uri, "+", " ")
	uri = string.gsub (uri, "%%(%x%x)",
		function(h) return string.char(tonumber(h,16)) end)
	return uri
end


------------------------------------
-- Malicious patterns
------------------------------------

local keywords = {
	'select','insert','update','delete',
	'union','table','from', 'where',
	'order by', 'group by', 'having',
	'susbtring', 'substr', 'ascii',
	'hex','unhex', 'rownum as'
}

local comments = { '%-%-', '#', '/%*.-%*/'}

local quotes = { '\'', '"', "`"}

local delim = {'%(', '%)'}

------------------------------------
-- Naive SQLi detection (Naxsi-like)
------------------------------------

local location = {'URI', 'COOKIE'}

sqli = haka.rule_group {
	name = "sqli",

	init = function (self, http)
		haka.log("filtering", "start : checking for sqli attacks")
		request = http.request
		request:dump()
		request.URI = percent_decode(request.uri):lower()
		request.COOKIE = request.headers['Cookie']
		request.sqli = {}
		request.sqli.score = {URI = 0, COOKIE = 0}
		request.sqli.msg = ''
	end,

	fini = function (self, pkt)
		haka.log("filtering", "end : checking for sqli attacks")
	end,

	continue = function (self, ret)
		if ret ~= nil then
			for key, value in pairs(sqli.score) do
				if value >= 8  then
					haka.log("filter", "SQLi attack detected !!!")
					haka.log.debug("filter", "Score = [ %s -- > %d ]", key, value)
					haka.log("filter", "Reason = [ %s]", request.sqli.msg)
					return nil
				end
			end
		end
		return true
	end
}


local function check_sqli(where, pattern, score, msg)
	sqli:rule {
		hooks = {"http-request"},
		eval = function (self, http)
			if http.request[where] then
				if http.request[where]:find(pattern) then
					sqli = http.request.sqli
					sqli.score[where] = sqli.score[where] + score
					sqli.msg = sqli.msg .. msg .. ' : '
					return sqli
				end
			end
			return nil
		end
	}
end


for loc = 1, #location do
	for key = 1, #keywords do
		check_sqli(location[loc], keywords[key], 4, 'SQL keywords in ' .. location[loc])
	end
	for key = 1, #comments do
		check_sqli(location[loc], comments[key], 4, 'SQL comments in ' .. location[loc])
	end
	for key = 1, #delim do
		check_sqli(location[loc], delim[key], 4, 'SQL stuff in ' .. location[loc])
	end
	for key = 1, #quotes do
		check_sqli(location[loc], quotes[key], 4, 'SQL probing')
	end

	check_sqli(location[loc], '0x%x%x%x%x+', 2, 'SQL hex encodings in' .. location[loc])
end

check_sqli('URI', ';', 4, 'SQL probing')
