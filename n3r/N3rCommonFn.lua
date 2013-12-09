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

_M.strContains = function(string, pattern)

	return string.find(string, pattern) ~= nil;
end;

_M.osParse = function(userAgent)

	if _M.strContains(userAgent, "Windows") then
		if _M.strContains(userAgent, "Windows NT 6.2") then
			return "Win 8";
		elseif _M.strContains(userAgent, "Windows NT 6.1") then
			return "Win 7";
		elseif _M.strContains(userAgent, "Windows NT 6.3") then
			return "Win 7";
		elseif _M.strContains(userAgent, "Windows NT 6.0") then
			return "Win Vista";
		elseif _M.strContains(userAgent, "Windows NT 5.2") then
			return "Win XP";
		elseif _M.strContains(userAgent, "Windows NT 5.1") then
			return "Win XP";
		elseif _M.strContains(userAgent, "Windows XP") then
			return "Win XP";
		elseif _M.strContains(userAgent, "Windows NT 5.01") then
			return "Win 2000";
		elseif _M.strContains(userAgent, "Windows NT 5.0") then
			return "Win 2000";
		elseif _M.strContains(userAgent, "Windows NT 4.0") then
			return "Win NT";
		elseif _M.strContains(userAgent, "Windows NT 4.10") then
			return "Win NT";
		elseif _M.strContains(userAgent, "Windows 98; Win 9x 4.90") then
			return "Win Me";
		elseif _M.strContains(userAgent, "Windows Me") then
			return "Win Me";
		elseif _M.strContains(userAgent, "Windows 98") then
			return "Win 98";
		elseif _M.strContains(userAgent, "Windows 95") then
			return "Win 95";
		elseif _M.strContains(userAgent, "Windows CE") then
			return "Win CE";
		elseif _M.strContains(userAgent, "Windows Phone") then
			return "Win Phone";
		elseif _M.strContains(userAgent, "wds") then
			return "Win Phone";
		else
			return nil;
		end;
	elseif  _M.strContains(userAgent, "Mac OS X") then
		if _M.strContains(userAgent, "iPod") then
			return "iPod";
		elseif _M.strContains(userAgent, "iPad") then
			return "iPad";
		elseif _M.strContains(userAgent, "iPhone") then
			return "iPhone";
		elseif _M.strContains(userAgent, "Macintosh") then
			return "Mac";
		else
			return nil;
		end;
	elseif  _M.strContains(userAgent, "Android") then
		return "Android";
	elseif _M.strContains(userAgent, "Symbian") then
		return "Symbian";
	elseif _M.strContains(userAgent, "JUC (Linux") then
		return "Linux";
	elseif _M.strContains(userAgent, "Linux") then
		return "Linux"
	elseif _M.strContains(userAgent, "BlackBerry") then
		return "BlackBerry";
	elseif _M.strContains(userAgent, "UCWEB") then
		if _M.strContains(userAgent, "Adr") then
			return "Android";
		elseif _M.strContains(userAgent, "iPh") then
			return "iPhone";
		elseif _M.strContains(userAgent, "wds") then
			return "Win Phone"
		elseif _M.strContains(userAgent, "Symbian") then
			return "Symbian";
		elseif _M.strContains(userAgent, "Nokia") then
			return "Nokia";
		elseif _M.strContains(userAgent, "Linux") then
			return "Linux";
		else
			return nil;
		end;
	else
		return nil;
	end;
end;


return _M;