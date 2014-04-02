------------------------------------
-- HTTP compliance
------------------------------------
-- check http method value
local http_methods = dict({ 'get', 'post', 'head', 'put', 'trace', 'delete', 'options' })

haka.rule {
	hook = haka.event('http', 'request'),
	eval = function (http, request)
		local method = request.method:lower()
		if not contains(http_methods, method) then
			haka.alert{
				description = string.format("non authorized http method '%s'", method),
				sources = haka.alert.address(http.flow.srcip),
				targets = {
					haka.alert.address(http.flow.dstip),
					haka.alert.service(string.format("tcp/%d", http.flow.dstport), "http")
				},
			}
			http:drop()
		end
	end
}

-- check http version value
local http_versions = dict({ '0.9', '1.0', '1.1' })

haka.rule {
	hook = haka.event('http', 'request'),
	eval = function (http, request)
		if not contains(http_versions, request.version) then
			haka.alert{
				description = string.format("unsupported http version '%s'", request.version),
				sources = haka.alert.address(http.flow.srcip),
				targets = {
					haka.alert.address(http.flow.dstip),
					haka.alert.service(string.format("tcp/%d", http.flow.dstport), "http")
				},
			}
			http:drop()
		end
	end
}

-- check content length value
haka.rule {
	hook = haka.event('http', 'request'),
	eval = function (http, request)
		local content_length = request.headers["Content-Length"]
		if content_length then
			content_length = tonumber(content_length)
			if content_length == nil or content_length < 0 then
				haka.alert{
					description = "corrupted content-length header value",
					sources = haka.alert.address(http.flow.srcip),
					targets = {
						haka.alert.address(http.flow.dstip),
						haka.alert.service(string.format("tcp/%d", http.flow.dstport), "http")
					},
				}
				http:drop()
			end
		end
	end
}
