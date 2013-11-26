local _Config = {
	["redisHost"] = "127.0.0.1",
	["redisPort"] = 6379,
	["flowLimitRate"] = "30%",



	["splitRules"] = {
		-- locationName abtest rule
		{
			["locationName"] = "abtest",
			["method"] = "flow",
			["testMode"] = true,
			["rule"] = {
				["2"] = "html/two.html",
				["default"] = "html/three.html",
			}
		},

		-- flow Limit Config
		{
			["locationName"] = "flowLimitConfig",
			["method"] = "flow",
			["testMode"] = false,
			["rule"] = {
				["2"] = "html/two.html",
				["default"] = "html/three.html",
			}
		},

		-- weight Config
		{
			["locationName"] = "weightConfig",
			["method"] = "weight",
			["testMode"] = false,
			["rule"] = {
				["20%"] = "html/one.html",
				["40%"] = "html/two.html",
				["default"] = "html/three.html"
			}
		},

		-- ip Config
		{
			["locationName"] = "ipConfig",
			["method"] = "ip",
			["testMode"] = true,
			["rule"] = {
				["192.168.0.1-192.168.2.1"] = "html/one.html",
				["192.168.126.4-192.168.126.5"] = "html/two.html",
				["default"] = "html/three.html"
			}
		}
	}
}



_Config.redisConfig = function()

	return _Config["redisHost"], _Config["redisPort"];
end;

_Config.getFlowLimitRate = function()

	return _Config["flowLimitRate"];
end;

_Config.getFlowLimitRateNumber = function()
	local pattern = "^(%d+)%%$";
	local flowLimitRate = _Config.getFlowLimitRate();
	local number = flowLimitRate:gsub(pattern, "%1");
	return tonumber(number);
end;

_Config.allSplitRules = function()

	return _Config["splitRules"];
end;

_Config.splitRule = function(locationName)
	local splitRules = _Config.allSplitRules();
	local splitRule = nil;
	for index, value in ipairs(splitRules) do
		if value["locationName"] == locationName then
			splitRule = value;
			break;
		end;
	end;

	return splitRule;
end;

local function main()
	print(_Config.getFlowLimitRateNumber());
end
--main();
return _Config;