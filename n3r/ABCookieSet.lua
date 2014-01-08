local _ABCookieSet = {

	_VERSION = '0.1'
}

local n3rCommonFn = require "n3r.N3rCommonFn";

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

_ABCookieSet.set = function()
	local html = "<h1>设置指定ab测试访问页面</h1>";
	for key, cacheValue in pairs(abConfigCache) do
		if key ~= "redisHost" and key ~= "redisPort" and key ~= "testMode" then
			local desc = cacheValue["desc"];
			html = html .. "<p/><p/>";
			html = html .. "当前的配置是 针对： " .. desc;
			local rules = cacheValue["rules"];
			local length = 0;
			local method = cacheValue["method"];
			local locationName = cacheValue["locationName"];
			local cookieKey = getCookieKey(cacheValue, locationName);
			
			local jsfunction = [[
					<script type="text/javascript">
					function setCookie]] .. method .. [[() {
						var chkObjs = document.getElementsByName("Fruit]] ..  method .. [[");
						var value = "";
		                for(var i=0;i<chkObjs.length;i++){
		                    if(chkObjs[i].checked){
		                        value = chkObjs[i].value;
		                        break;
		                    }
		                }
		                var cookie = "]] .. cookieKey .. [[ = " + value;
						document.cookie=cookie;
					}
					</script>
					]];
			html = html .. jsfunction;
			html = html .. "<table border=1><tr>";
			if "ip" == method or "weight" == method then
				for index, rule in ipairs(rules) do
					local page = rule["page"];
					html = html .. "<td><input name=Fruit" .. method .. " type=radio value=" .. page .. " />" .. page .. "</td>";
					length = length + 1;
				end;
			elseif "flow" == method then
					local defaultPage = rules["defaultPage"];
					local redirectPage = rules["redirectPage"];
					html = html .. "<td><input name=Fruit" .. method .. " type=radio value=" .. defaultPage .. " />" .. defaultPage .. "</td>";
					html = html .. "<td><input name=Fruit" .. method .. " type=radio value=" .. redirectPage .. " />" .. redirectPage .. "</td>";
					length = 2;
			else
				local defaultPage = rules["defaultPage"];
				html = html .. "<td><input name=Fruit" .. method .. " type=radio value=" .. defaultPage .. " />" .. defaultPage .. "</td>";
				length = 1;
				for ruleKey, page in pairs(rules) do
					if "defaultPage" ~= ruleKey then
					html = html .. "<td><input name=Fruit" .. method .. " type=radio value=" .. page .. " />" .. page .. "</td>";
					length = length + 1;
					end;
				end;
			end;
			local button = "<input type=button value=设置固定访问页面  onclick=setCookie".. method .. "(); />";
			html = html .. "</tr><tr><td colspan=" .. length .. " align=center>".. button .."</td></tr></table>";
		end;
	end;	
	ngx.say(html);
end;



return _ABCookieSet;