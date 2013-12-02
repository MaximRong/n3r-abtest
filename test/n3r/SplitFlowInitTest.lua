local splitFlowInit = require("n3r.SplitFlowInit");

describe("test SplitFlowInit", function()
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