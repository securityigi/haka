-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

local http = require("protocol/http")

http.install_tcp_rule(80)

haka.rule {
	hook = haka.event('http', 'request'),
	eval = function (http, request)
		print("HTTP REQUEST")
		haka.debug.pprint(request, nil, nil, { haka.debug.hide_underscore, haka.debug.hide_function })
	end
}

haka.rule {
	hook = haka.event('http', 'response'),
	eval = function (http, response)
		print("HTTP RESPONSE")
		haka.debug.pprint(response, nil, nil, { haka.debug.hide_underscore, haka.debug.hide_function })
	end
}
