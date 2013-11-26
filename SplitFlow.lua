--------------------------------- variable --------------------------------------------
local _M = {

	_VERSION = '0.1'
}
local remote_addr = ngx.var.remote_addr; -- Òª¸Ä³Éx-forwarded-for
local functionM = {};
local n3rCommonFn = require "n3r.N3rCommonFn";
local n3rSplitFlowConfig = require "n3r.N3rSplitFlowConfig";

--------------------------------- function --------------------------------------------

local ipSplitFlowFn = function(locationConfig)
	local loadLocationRules = locationConfig["rules"];
	local remoteInt = n3rCommonFn.addressNo(remote_addr);
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
	local flowLimitRate = n3rSplitFlowConfig.getFlowLimitRateNumber();
	local randomNum = math.random(1, 100);

	local loadLocationRules = locationConfig["rules"];
	local limitTime = loadLocationRules["limitTime"];
	local sum = locationConfig["param"];
	local loadLocationRules = locationConfig["rules"];

	if randomNum <= flowLimitRate and limitTime >= sum then
		sum = sum + 1;
		locationConfig["param"] = sum;
		return loadLocationRules["redirectPage"];
	end;

	return loadLocationRules["defaultPage"];
end;

functionM["ip"] = ipSplitFlowFn;
functionM["weight"] = weightSplitFlowFn;
functionM["flow"] = flowSplitFlowFn;

_M.rotePage = function(locationName)

	local locationConfig = abConfigCache[locationName];
	if not locationConfig then
		ngx.log(ngx.ERR, "location name not found : ", locationName);
		return ngx.exit(500);
	end;

	local method = locationConfig["method"];
	local fn = functionM[method];
	local redirectPage = fn(locationConfig);
	ngx.say(redirectPage);

	local redis = require "resty.redis";
	local red = redis:new();

	red:set_timeout(1000) -- 1 second
	local redisHost, redisPort = n3rSplitFlowConfig.redisConfig();
	local ok, err = red:connect(redisHost, redisPort)
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