local n3rCommonFn = require("n3r.N3rCommonFn");  
local splitFlowInit = require("n3r.SplitFlowInit");
local splitFlow = require("n3r.SplitFlow");

describe("test N3rCommonFn #N3rCommonFn", function()
	it("check addressNo", function()
		local actual = n3rCommonFn.addressNo("192.168.1.2");
		assert.are.equals(192168001002, actual);
	end)

	it("check booleanValue", function()
		assert.is_true(n3rCommonFn.booleanValue("true"));
		assert.is_true(n3rCommonFn.booleanValue("yes"));
		assert.is_true(n3rCommonFn.booleanValue("on"));
		assert.is_true(n3rCommonFn.booleanValue(true));
		assert.is_false(n3rCommonFn.booleanValue(nil));
		assert.is_false(n3rCommonFn.booleanValue(false));
		assert.is_false(n3rCommonFn.booleanValue("error"));
	end)
	
	it("check osParse", function()
		assert.are.equals("Win 7", n3rCommonFn.osParse("Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.57 Safari/537.36"));
	end)
end)

describe("test SplitFlowInit #SplitFlowInit", function()
	local abConfigCache = splitFlowInit.init();

	it("check init flowLimitConfig", function()
		local flowLimitConfig = abConfigCache['flowLimitConfig'];
		local rules = flowLimitConfig['rules'];

		assert.are.equals(2, rules["limitTime"]);
		assert.are.equals("html/three.html", rules["defaultPage"]);
		assert.are.equals("html/two.html", rules["redirectPage"]);
		assert.are.equals(0, flowLimitConfig["param"]);
	end)

	it("check init weightConfig", function()
		local weightConfig = abConfigCache['weightConfig'];
		local rules = weightConfig['rules'];

		for index, rule in ipairs(rules) do

			local page = rule['page'];
			local min = rule['min'];
			local max = rule['max'];
			local d = max - min;
			if d == 2000 then
				assert.are.equals("html/one.html", page);
			elseif d == 4000 and max == 10000 then
				assert.are.equals("html/three.html", page);
			else
				assert.are.equals("html/two.html", page);
			end;
		end;

		assert.are.equals(10000, weightConfig["param"]);
	end)

	it("check init ipConfig", function()
		local ipConfig = abConfigCache['ipConfig'];
		local rules = ipConfig['rules'];

		for index, rule in ipairs(rules) do

			local page = rule['page'];
			if page == "html/one.html" then
				assert.are.equals(192168000001, rule['min']);
				assert.are.equals(192168002001, rule['max']);
				assert.are.equals(1, rule['type']);
			elseif page == "html/two.html"then
				assert.are.equals(192168126004, rule['min']);
				assert.are.equals(192168126005, rule['max']);
				assert.are.equals(1, rule['type']);
			else
				assert.are.equals(0, rule['type']);
			end;
		end;

	end)

end)


abConfigCache = splitFlowInit.init();
ngx = {};
ngx.log = function(error, msg, name)
	return error .. msg .. name;
end;
ngx.header = {};
ngx.say = function(msg)
	return msg;
end;
ngx.var = {
	remote_addr = "192.168.126.4",
	http_user_agent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.57 Safari/537.36"
};


describe("test splitFlow #splitFlow", function()
	it("check rotePage by flowLimitConfig", function()
		local page = splitFlow.rotePage("flowLimitConfig");
		assert.are.equals("html/two.html", page);
		
		page = splitFlow.rotePage("flowLimitConfig");
		assert.are.equals("html/two.html", page);
		
		page = splitFlow.rotePage("flowLimitConfig");
		assert.are.equals("html/three.html", page);
	end)
	
	it("check rotePage by ipConfig", function()
		local page = splitFlow.rotePage("ipConfig");
		assert.are.equals("html/two.html", page);
	end)
	
	it("check rotePage by weightConfig", function()
		local page = splitFlow.rotePage("weightConfig");
		assert.is.truthy(page);
	end)
	
	it("check rotePage by osConfig", function()
		local page = splitFlow.rotePage("osConfig");
		assert.are.equals("html/one.html", page);
	end)
end)