local _M = {

	_VERSION = '0.1'
}

local addressNo = function(address)
	local pattern = "^(%d+)%.(%d+)%.(%d+)%.(%d+)$";
	local no1 = tonumber((address:gsub(pattern, "%1"))) * 1000000000;
	local no2 = tonumber((address:gsub(pattern, "%2"))) * 1000000;
	local no3 = tonumber((address:gsub(pattern, "%3"))) * 1000;
	local no4 = tonumber((address:gsub(pattern, "%4")));
	return no1 + no2 + no3 + no4;
end;

local loadLocationConfig = function(locationName)
	local locationConfig = abConfigCache[locationName];
	if locationConfig ~= nil then
		return locationConfig
	end;
	
	local redis = require "resty.redis";
	local red = redis:new();

	red:set_timeout(1000) -- 1 second
	local ok, err = red:connect("127.0.0.1", 6379)
	if not ok then
		ngx.log(ngx.ERR, "failed to connect to redis: ", err);
		return ngx.exit(500);
	end;

	local locationConfigKey = "n3r.ab.location." .. locationName;
	if red:exists(locationConfigKey) == 0 then
		ngx.log(ngx.ERR, "not found redis key: " .. locationConfigKey, err);
		return ngx.exit(500);
	end;

	local locationConfigStr, err = red:get(locationConfigKey);
	if not locationConfigStr then
		ngx.log(ngx.ERR, "failed to get redis key: " .. locationConfigKey, err);
		return ngx.exit(500);
	end;

	local cjson = require "cjson";
	locationConfig = cjson.decode(locationConfigStr);

	local ruleStr = locationConfig["rule"];
	local ruleJson = cjson.decode(ruleStr);

	local rules = {};

	for key, value in pairs(ruleJson) do
		local rule = {};

		if key:find("default") ~= nil then
			rule['type'] = 0; -- default type
		else
			rule['type'] = 1; -- min/max ip type
			local pattern = "^(%d+%.%d+%.%d+%.%d+)-(%d+%.%d+%.%d+%.%d+)$";
			local min = addressNo(key:gsub(pattern, "%1"));
			local max = addressNo(key:gsub(pattern, "%2"));
			rule['min'] = min;
			rule['max'] = max;
		end;
		rule['page'] = value;
		table.insert(rules, rule);
	end;
	locationConfig['rules'] = rules;
	abConfigCache[locationName] = locationConfig;
	return locationConfig;
end;

_M.rotePage = function(locationName)

	local locationConfig = loadLocationConfig(locationName);
	for key, value in pairs(locationConfig) do
		if key == 'rules' then
			ngx.say('rules : ');
			for i, v in ipairs(value) do
				for j, k in pairs(v) do
					ngx.say("rule name is: " .. j .. " ; value is: " .. k);
				end;
			end;
		else
			ngx.say("key name is: " .. key .. " ; value is: " .. value);
		end;
	end;
end;

_M.redirect = function(locationName)
	ngx.say(locationName);
	return locationName;
end;

return _M;