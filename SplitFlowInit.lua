local _M = {

	_VERSION = '0.1'
}


_M.init = function()
	local abConfigCache = {};
	local path = os.getenv("PWD");

	local cjson = require "cjson";
	local file = io.open(path .. "/SplitFlow.json", "r");
	local ruleConfigs = cjson.decode(file:read("*all"));
	file:close();

	local n3rCommonFn = require "n3r.N3rCommonFn";

	for index, locationConfig in ipairs(ruleConfigs) do

		local locationName = locationConfig["location"];

		local ruleStr = locationConfig["rule"];
		local ruleJson = cjson.decode(ruleStr);

		local rules = {};
		local param = nil;
		local method = locationConfig["method"];
		if method == "ip" then
			for key, value in pairs(ruleJson) do
				local rule = {};

				if key == "default" then
					rule['type'] = 0; -- default type
				else
					rule['type'] = 1; -- min/max ip type
					local pattern = "^(%d+%.%d+%.%d+%.%d+)-(%d+%.%d+%.%d+%.%d+)$";
					local min = n3rCommonFn.addressNo(key:gsub(pattern, "%1"));
					local max = n3rCommonFn.addressNo(key:gsub(pattern, "%2"));
					rule['min'] = min;
					rule['max'] = max;
				end;
				rule['page'] = value;
				table.insert(rules, rule);
			end;
		elseif method == "weight" then
			param = 0;
			local periphery = 0;
			for key, value in pairs(ruleJson) do
				local rule = {};

				local min = periphery;
				local max = min + key;
				periphery = max;
				rule['min'] = min;
				rule['max'] = max;
				rule['page'] = value;
				table.insert(rules, rule);
				param = param + key;
			end;
		else
			param = 0;
			for key, value in pairs(ruleJson) do
				if key == "default" then
					rules["defaultPage"] = value; -- default type
				else
					rules["limitTime"] = tonumber(key);
					rules["redirectPage"] = value;
				end;
			end;
		end;

		locationConfig['rules'] = rules;
		locationConfig['param'] = param;
		abConfigCache[locationName] = locationConfig;
	end;






	--[[
	local redis = require "resty.redis";
	local red = redis:new();

	red:set_timeout(1000) -- 1 second
	local ok, err = red:connect("127.0.0.1", 6379)
	if not ok then
	ngx.log(ngx.ERR, "failed to connect to redis: ", err);
	return ngx.exit(500);
	end;

	local locationConfigKeysStr = "n3r.ab.location.*";
	local locationConfigKeys = red:keys(locationConfigKeysStr);

	local n3rCommonFn = require "n3r.N3rCommonFn";

	for index, locationConfigKey in ipairs(locationConfigKeys) do

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
	local locationConfig = cjson.decode(locationConfigStr);

	local ruleStr = locationConfig["rule"];
	local ruleJson = cjson.decode(ruleStr);

	local rules = {};
	local param = nil;

	local method = locationConfig["method"];
	if method == "ip" then
	for key, value in pairs(ruleJson) do
	local rule = {};

	if key == "default" then
	rule['type'] = 0; -- default type
	else
	rule['type'] = 1; -- min/max ip type
	local pattern = "^(%d+%.%d+%.%d+%.%d+)-(%d+%.%d+%.%d+%.%d+)$";
	local min = n3rCommonFn.addressNo(key:gsub(pattern, "%1"));
	local max = n3rCommonFn.addressNo(key:gsub(pattern, "%2"));
	rule['min'] = min;
	rule['max'] = max;
	end;
	rule['page'] = value;
	table.insert(rules, rule);
	end;
	elseif method == "weight" then
	param = 0;
	local periphery = 0;
	for key, value in pairs(ruleJson) do
	local rule = {};

	local min = periphery;
	local max = min + key;
	periphery = max;
	rule['min'] = min;
	rule['max'] = max;
	rule['page'] = value;
	table.insert(rules, rule);
	param = param + key;
	end;
	else
	param = 0;
	for key, value in pairs(ruleJson) do
	if key == "default" then
	rules["defaultPage"] = value; -- default type
	else
	rules["limitTime"] = tonumber(key);
	rules["redirectPage"] = value;
	end;
	end;
	end;

	locationConfig['rules'] = rules;
	locationConfig['param'] = param;

	local pattern = "^.+%.+(%w+)$";
	local locationName = locationConfigKey:gsub(pattern, "%1");
	abConfigCache[locationName] = locationConfig;
	end;
	]]
	return abConfigCache;
end;

return _M;