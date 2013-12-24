local _M = {
	_VERSION = '0.1'
}


_M.init = function(config)
	local abConfigCache = {};
	
	abConfigCache["redisHost"] = config["redisHost"];
	abConfigCache["redisPort"] = config["redisPort"];
	abConfigCache["testMode"] = config["testMode"];
	
	local n3rCommonFn = require "n3r.N3rCommonFn";
	local ruleConfigs = config["splitRules"];

	for index, locationConfig in ipairs(ruleConfigs) do

		local configRule = locationConfig["rule"];

		local rules = {};
		local param = nil;
		local method = locationConfig["method"];
		
		if method == "ip" then
			for key, value in pairs(configRule) do
				local rule = {};
				local pattern = "^(%d+%.%d+%.%d+%.%d+)-(%d+%.%d+%.%d+%.%d+)$";

				if key == "default" then
					rule['type'] = 0; -- default type
				else
					rule['type'] = 1; -- min/max ip type
					local min = n3rCommonFn.addressNo(key:gsub(pattern, "%1"));
					local max = n3rCommonFn.addressNo(key:gsub(pattern, "%2"));
					rule['min'] = min;
					rule['max'] = max;
				end;
				rule['page'] = value;
				table.insert(rules, rule);
			end;
		elseif method == "weight" then
			param = 10000;
			local periphery = 0;
			local pattern = "^(%d+)%%$";
			local defaultPage =  nil;
			for key, value in pairs(configRule) do
				local rule = {};
				if key == "default" then
					defaultPage = value; -- default type
				else
					local rate = tonumber((key:gsub(pattern, "%1"))) * 100;
					local min = periphery;
					local max = min + rate;
					periphery = max;

					rule['min'] = min;
					rule['max'] = max;
					rule['page'] = value;
					table.insert(rules, rule);
				end;
			end;
			local rule = {};
			rule['min'] = periphery;
			rule['max'] = 10000;
			rule['page'] = defaultPage;
			table.insert(rules, rule);
		elseif method == "flow" then
			param = 0;
			for key, value in pairs(configRule) do
				if key == "default" then
					rules["defaultPage"] = value; -- default type
				else
					rules["limitTime"] = tonumber(key);
					rules["redirectPage"] = value;
				end;
			end;
		elseif method == "var" then
			param = locationConfig["var"];
			for key, value in pairs(configRule) do
				if key == "default" then
					rules["defaultPage"] = value; -- default type
				else
					rules[key] = value;
				end;
			end;
		else
			for key, value in pairs(configRule) do
				if key == "default" then
					rules["defaultPage"] = value; -- default type
				else
					rules[key] = value;
				end;
			end;
		end;

		locationConfig['rules'] = rules;
		locationConfig['param'] = param;

		local locationName = locationConfig['locationName'];
		abConfigCache[locationName] = locationConfig;
	end;

	return abConfigCache;
end;

return _M;