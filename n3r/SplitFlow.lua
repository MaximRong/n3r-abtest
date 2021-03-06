--------------------------------- variable --------------------------------------------
local _M = {
	_VERSION = '0.1'
}

local functionM = {};
local n3rCommonFn = require "n3r.N3rCommonFn";
local cjson = require "cjson";

--------------------------------- function --------------------------------------------

local ipSplitFlowFn = function(locationConfig)
	local remote_addr = ngx.var.remote_addr; 
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
	math.randomseed( tostring(os.time()):reverse() );
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
	local flowLimitRate = n3rCommonFn.rateToNumber(locationConfig["flowLimitRate"]);
	local randomNum = math.random(1, 100);

	local loadLocationRules = locationConfig["rules"];
	local limitTime = loadLocationRules["limitTime"];
	local sum = locationConfig["param"];
	local loadLocationRules = locationConfig["rules"];

	if randomNum <= flowLimitRate and limitTime > sum then
		sum = sum + 1;
		locationConfig["param"] = sum;
		return loadLocationRules["redirectPage"];
	end;

	return loadLocationRules["defaultPage"];
end;

local osSplitFlowFn = function(locationConfig)

	local os = n3rCommonFn.osParse(ngx.var.http_user_agent);
	local loadLocationRules = locationConfig["rules"];
	
	if os == nil then
		return loadLocationRules["computer"];
	end;

	local redirectPage = loadLocationRules[os];
	return redirectPage == nil and loadLocationRules["computer"] or redirectPage;

end;

local varSplitFn = function(locationConfig)

	local key = locationConfig["param"];
	local value = ngx.var[key];

	local loadLocationRules = locationConfig["rules"];
	local redirectPage = loadLocationRules[value];
	return redirectPage == nil and loadLocationRules["defaultPage"] or redirectPage;
end;

functionM["ip"] = ipSplitFlowFn;
functionM["weight"] = weightSplitFlowFn;
functionM["flow"] = flowSplitFlowFn;
functionM["os"] = osSplitFlowFn;
functionM["var"] = varSplitFn;

local recordRedirectPage = function(locationName, redirectPage)
	local redis = require "resty.redis";
	local red = redis:new();

	red:set_timeout(1000) -- 1 second
	local redisHost = abConfigCache["redisHost"];
	local redisPort = abConfigCache["redisPort"];
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

local getCookieKey = function(locationConfig, locationName)
	local cookie = locationName;
	local configCookie = locationConfig["cookie"];
	if configCookie ~= nil then
		local configCookies = n3rCommonFn.split(configCookie, "[^,%s]+");
		for key, value in ipairs(configCookies) do
			if string.find(value, "%$") ~= nil then
				local var = string.sub(value, 2);
				local add = ngx.var[var];
				cookie = cookie .. add;
			else
				cookie = cookie .. value;
			end
		end;
	end;
	return cookie;
end;

_M.rotePage = function(locationName)
	
	local locationConfig = abConfigCache[locationName];
	if not locationConfig then
		ngx.log(ngx.ERR, "location name not found : ", locationName);
		return ngx.exit(500);
	end;
	
	local plan = abConfigCache["plan"];

	local cookieKey = getCookieKey(locationConfig, locationName);
	local cookiePageAddr = ngx.var["cookie_" .. cookieKey];
	local testMode = n3rCommonFn.booleanValue(abConfigCache["testMode"]);
	
	if not testMode and cookiePageAddr ~= nil then
		local expires = 3600 * 24;
		local expires = ngx.cookie_time(ngx.time() + expires);
		local cachePageAddr = ndk.set_var.set_decode_base32(cookiePageAddr);
		cachePageAddr = ndk.set_var.set_decrypt_session(cachePageAddr);
		local r = plan[cachePageAddr];
		ngx.header["Set-Cookie"] = "n3ABresult=" .. locationName .. "_" .. r .. "; Domain=.10010.com; Path=/; Expires=" .. expires;
		return cachePageAddr;
	end;

	local method = locationConfig["method"];
	local fn = functionM[method];
	
	-- record cookie
	local redirectPage = fn(locationConfig);
	local r = plan[redirectPage];
	
	local expires = 3600 * 24;
	local cookies = {};
	local expires = ngx.cookie_time(ngx.time() + expires);
	local cookieValue = ndk.set_var.set_encrypt_session(redirectPage);
	cookieValue = ndk.set_var.set_encode_base32(cookieValue);
	table.insert(cookies, cookieKey .. "=" .. cookieValue .. "; Path=/; Domain=.10010.com; Expires=" .. expires);
	table.insert(cookies, "n3ABresult=" .. locationName .. "_" .. r .. "; Path=/; Domain=.10010.com; Expires=" .. expires);
	ngx.header["Set-Cookie"] = cookies;
	
	--[[
	if testMode then
		recordRedirectPage(locationName, redirectPage);
	end;
	]]
	return redirectPage;
end;

_M.redirect = function(locationName)
	ngx.say(locationName);

	return locationName;
end;

return _M;