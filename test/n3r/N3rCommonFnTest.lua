local n3rCommonFn = require("n3r.N3rCommonFn");

describe("test N3rCommonFn", function()
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
end)
