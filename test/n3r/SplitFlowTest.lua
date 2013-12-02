local splitFlow = require("n3r.SplitFlow");
local splitFlowInit = require("n3r.SplitFlowInit");

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
	remote_addr = "192.168.126.4"
};


describe("test splitFlow", function()
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
end)