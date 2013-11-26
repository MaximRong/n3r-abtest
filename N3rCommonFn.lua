local _M = {

	_VERSION = '0.1'
}

_M.addressNo = function(address)
	local pattern = "^(%d+)%.(%d+)%.(%d+)%.(%d+)$";
	local no1 = tonumber((address:gsub(pattern, "%1"))) * 1000000000;
	local no2 = tonumber((address:gsub(pattern, "%2"))) * 1000000;
	local no3 = tonumber((address:gsub(pattern, "%3"))) * 1000;
	local no4 = tonumber((address:gsub(pattern, "%4")));
	return no1 + no2 + no3 + no4;
end;

_M.booleanValue = function(str)
	if str == "yes" or str == "true" or str == "on" or str == true then
		return true;
	end;

	return false;
end;


return _M;