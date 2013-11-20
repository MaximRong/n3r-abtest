local _SeigeResult = {

	_VERSION = '0.1'
}

_SeigeResult.result = function()
	local redis = require "resty.redis";
	local red = redis:new();

	red:set_timeout(1000) -- 1 second
	local ok, err = red:connect("127.0.0.1", 6379)
	if not ok then
		ngx.log(ngx.ERR, "failed to connect to redis: ", err);
		return ngx.exit(500);
	end;

	local siegeResultKeyPerfix = "n3r.ab.siege.result.*";
	local siegeResultKeys = red:keys(siegeResultKeyPerfix);

	local html = "";
	local pattern = "^.+%.+(%w+)$";
	for key, value in ipairs(siegeResultKeys) do
		html = html .. "localName is :  " .. value:gsub(pattern, "%1") .. " </br><table>";
		html = html .. "<table border=1><tr><td>page</td><td>count</td></tr>";
		local siegeResultStr, err = red:get(value);
		local cjson = require "cjson";
		local siegeResult = cjson.decode(siegeResultStr);

		for page, count in pairs(siegeResult) do
			html = html .. "<tr><td>" .. page .. "</td><td>" .. count .. "</td></tr>";
		end;
		html = html .. "</table>";
	end;
	
	ngx.say(html);

end;



return _SeigeResult;