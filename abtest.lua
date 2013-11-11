ngx.header.content_type = "text/plain";
--------------------------------- variable --------------------------------------------
local weightRules = {};
local weightSum = 0;
local remote_addr = ngx.var.remote_addr;
--------------------------------- initial  --------------------------------------------
local redis = require "resty.redis";
local red = redis:new();

red:set_timeout(1000) -- 1 second
local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
   ngx.log(ngx.ERR, "failed to connect to redis: ", err);
   return ngx.exit(500);
end;


if red:exists(remote_addr) == 1 then
    local cachePageAddr, err = red:get(ngx.var.remote_addr);
	if not cachePageAddr then
		    ngx.log(ngx.ERR, "failed to get redis key: ", err);
		    return ngx.exit(500);
	end;

 	ngx.redirect(cachePageAddr);
	--ngx.say(cachePageAddr);
	return;
end;



--------------------------------- function --------------------------------------------
local addressNo = function(address)
     local pattern = "^(%d+)%.(%d+)%.(%d+)%.(%d+)$";
     local no1 = tonumber((address:gsub(pattern, "%1"))) * 1000000000;
     local no2 = tonumber((address:gsub(pattern, "%2"))) * 1000000;
     local no3 = tonumber((address:gsub(pattern, "%3"))) * 1000;
     local no4 = tonumber((address:gsub(pattern, "%4")));
	 return no1 + no2 + no3 + no4;
end;

local remoteInt = addressNo(remote_addr);

local parseRule = function(line)
	 local ret = nil;
     if line:find("default") ~= nil then
		 local pattern = "^%s*default%s+(.+)%s*;%s*$";
		 ret = line:gsub(pattern, "%1");
		 return ret;
     end;
     local pattern = "^%s*(%d+%.%d+%.%d+%.%d+)-(%d+%.%d+%.%d+%.%d+)%s+(.+)%s*;%s*$";
	 local addressH = addressNo(line:gsub(pattern, "%1"));
	 local addressB = addressNo(line:gsub(pattern, "%2"));
	 if addressH <= remoteInt and remoteInt <= addressB then
		 ret = line:gsub(pattern, "%3");
     end;
	 return ret;
end;

local parseRuleByWeigth = function(line)
	 local pattern = "^%s*(%d+)%s+(.+)%s*;%s*$";
	 local weight = line:gsub(pattern, "%1");
	 local pageAddr = line:gsub(pattern, "%2");
	 weightRules[weight] = pageAddr;
	 weightSum = weightSum + weight;
end;

local initialWeightRules = function(file)
    if next(weightRules) ~= nil then
		return;
	end;
	line = file:read("*l");
	while line ~= nil do
		if line:find("%w") ~= nil and line:find("}") == nil then
		    parseRuleByWeigth(line);
		end;
		line = file:read("*l");
	end;
end;
--------------------------------- main ------------------------------------------------

local file = io.open("/home/maxim/App/openresty/nginx/conf/abtest_count.conf", "r");
local line = file:read("*l");
local fork = nil;
while line ~= nil do 
   if nil ~= line:find("%$") then
	  -- when $ match, fork  
      fork = line:gsub("^%s*%$%s*(%w+)%s*{%s*$", "%1");
	  break;
   end;
 line = file:read("*l");
end;

local pageAddr = nil;
if fork == "address" then
   
    line = file:read("*l");
	while line ~= nil do
		if line:find("%w") ~= nil and line:find("}") == nil then
		    local _pageAddr = parseRule(line);
			if(nil ~= _pageAddr) then
				pageAddr = _pageAddr;
				break;
			end;
		end;
		line = file:read("*l");
	end;

elseif fork == "weight" then
	
	initialWeightRules(file);
	local randomNum = math.random(1, weightSum);
	local periphery = 0;
	for weight, _pageAddr in pairs(weightRules) do 
		periphery = periphery + weight;
		if 0 < randomNum and randomNum <= periphery then
			pageAddr = _pageAddr;
			break;
		end;
	end
	

elseif fork == "reqLimit" then
	
    line = file:read("*l");
	while line ~= nil do
		if line:find("%w") ~= nil and line:find("}") == nil then
			local pattern = "^%s*(%d+)%s+(.+)%s*;%s*$";
			local defaultPageAddr = nil;
			if line:find("default") ~= nil then
				defaultPageAddr = line:gsub("^%s*default%s+(.+)%s*;%s*$", "%1");
				pageAddr = defaultPageAddr;
				break;
			end;
			
			local confReqCount = tonumber((line:gsub(pattern, "%1")));
			local _pageAddr = line:gsub(pattern, "%2");
			
		    local sharedMem = ngx.shared.sharedMem;
	     	local reqCount = sharedMem:get("reqCount");
			reqCount = reqCount + 1;

			if confReqCount >= reqCount then
			    sharedMem:set("reqCount", reqCount);
				pageAddr = _pageAddr;
				break;
			end;

		end;
		line = file:read("*l");
	end;
	
end;

file:close();

red:set(ngx.var.remote_addr, pageAddr);
ngx.redirect(pageAddr);
