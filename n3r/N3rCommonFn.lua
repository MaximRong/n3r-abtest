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

_M.split = function(str, pat)
	local t = {};
	for i in string.gmatch(str, pat) do
		table.insert(t, i);
	end
	return t;
end;

_M.strContains = function(string, pattern)

	return string.find(string, pattern) ~= nil;
end;

_M.rateToNumber = function(string)
	local pattern = "^(%d+)%%$";
	local number = string:gsub(pattern, "%1");
	return tonumber(number);
end;

_M.osParse = function(userAgent)

	if _M.strContains(userAgent, "Windows") then
		if _M.strContains(userAgent, "Windows NT 6.2") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows NT 6.1") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows NT 6.3") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows NT 6.0") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows NT 5.2") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows NT 5.1") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows XP") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows NT 5.01") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows NT 5.0") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows NT 4.0") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows NT 4.10") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows 98; Win 9x 4.90") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows Me") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows 98") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows 95") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows CE") then
			return "computer";
		elseif _M.strContains(userAgent, "Windows Phone") then
			return "phone";
		elseif _M.strContains(userAgent, "wds") then
			return "phone";
		else
			return nil;
		end;
	elseif  _M.strContains(userAgent, "Mac OS X") then
		if _M.strContains(userAgent, "iPod") then
			return "phone";
		elseif _M.strContains(userAgent, "iPad") then
			return "phone";
		elseif _M.strContains(userAgent, "iPhone") then
			return "phone";
		elseif _M.strContains(userAgent, "Macintosh") then
			return "computer";
		else
			return nil;
		end;
	elseif  _M.strContains(userAgent, "Android") then
		return "phone";
	elseif _M.strContains(userAgent, "Symbian") then
		return "phone";
	elseif _M.strContains(userAgent, "BlackBerry") then
		return "phone";
	elseif _M.strContains(userAgent, "JUC (Linux") then
    return "computer";
  elseif _M.strContains(userAgent, "Linux") then
    return "computer"
	elseif _M.strContains(userAgent, "UCWEB") then
		if _M.strContains(userAgent, "Adr") then
			return "phone";
		elseif _M.strContains(userAgent, "iPh") then
			return "phone";
		elseif _M.strContains(userAgent, "wds") then
			return "phone"
		elseif _M.strContains(userAgent, "Symbian") then
			return "phone";
		elseif _M.strContains(userAgent, "Nokia") then
			return "phone";
		elseif _M.strContains(userAgent, "Linux") then
			return "computer";
		else
			return nil;
		end;
	else
		return nil;
	end;
end;


return _M;