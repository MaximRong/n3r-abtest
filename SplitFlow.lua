--------------------------------- variable --------------------------------------------
local _M = {

	_VERSION = '0.1'
}
local remote_addr = ngx.var.remote_addr;
local functionM = {};

--------------------------------- function --------------------------------------------
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
				local min = addressNo(key:gsub(pattern, "%1"));
				local max = addressNo(key:gsub(pattern, "%2"));
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
	return locationConfig;
end;

local ipSplitFlowFn = function(locationConfig)
	local loadLocationRules = locationConfig["rules"];
	local remoteInt = addressNo(remote_addr);
	local defaultPage = nil;
	local redirect = nil;

	for index, rule in ipairs(loadLocationRules) do
		local type = rule["type"];
		if type == 0 then
			defaultPage = rule["page"];
		else
			local min = rule["min"];
			local max = rule["max"];
			if min <= remoteInt and remoteInt <= max then
				redirect = rule["page"];
			end;
		end;
	end;

	return redirect and redirect or defaultPage;
end;

local weightSplitFlowFn = function(locationConfig)
	local sum = locationConfig["param"];
	local randomNum = math.random(1, sum);

	local loadLocationRules = locationConfig["rules"];

	local redirect = nil;
	for index, rule in ipairs(loadLocationRules) do
		if rule["min"] < randomNum and randomNum <= rule["max"] then
			redirect = rule["page"];
			break;
		end;
	end;

	return redirect;
end;

local flowSplitFlowFn = function(locationConfig)
	local sum = locationConfig["param"];
	sum = sum + 1;
	locationConfig["param"] = sum;

	local loadLocationRules = locationConfig["rules"];
	local limitTime = loadLocationRules["limitTime"];
	return limitTime >= sum and loadLocationRules["redirectPage"] or loadLocationRules["defaultPage"];
end;

functionM["ip"] = ipSplitFlowFn;
functionM["weight"] = weightSplitFlowFn;
functionM["flow"] = flowSplitFlowFn;

_M.rotePage = function(locationName)

	local locationConfig = loadLocationConfig(locationName);
	--	for key, value in pairs(locationConfig) do
	--		if key == 'rules' then
	--			for i, v in ipairs(value) do
	--				for j, k in pairs(v) do
	--					ngx.say("rule name is: " .. j .. " ; value is: " .. k);
	--				end;
	--			end;
	--		else
	--			ngx.say("key name is: " .. key .. " ; value is: " .. value);
	--		end;
	--	end;

	local method = locationConfig["method"];
	local fn = functionM[method];
	local redirectPage = fn(locationConfig);
	ngx.say(redirectPage);

	local redis = require "resty.redis";
	local red = redis:new();

	red:set_timeout(1000) -- 1 second
	local ok, err = red:connect("127.0.0.1", 6379)
	if not ok then
		ngx.log(ngx.ERR, "failed to connect to redis: ", err);
		return ngx.exit(500);
	end;

	local siegeResultKey = "n3r.ab.siege.result." .. locationName;
	local siegeResult = nil;
	if red:exists(siegeResultKey) == 1 then
		local siegeResultStr, err = red:get(siegeResultKey);
		if not siegeResultStr then
			ngx.log(ngx.ERR, "failed to get redis key: " .. siegeResultKey, err);
			return ngx.exit(500);
		end;

		local cjson = require "cjson";
		siegeResult = cjson.decode(siegeResultStr);
		local count = siegeResult[redirectPage];
		siegeResult[redirectPage] = count ~= nil and count + 1 or 1;
	else
		siegeResult = {};
		siegeResult[redirectPage] = 1;
	end;
	
	local siegeResultStr = cjson.encode(siegeResult);
	red:set(siegeResultKey, siegeResultStr);
end;

_M.redirect = function(locationName)
	ngx.say(locationName);


	return locationName;
end;

return _M;