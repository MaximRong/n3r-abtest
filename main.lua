local test = function()
	print("this is lua test function.");
end

local function main()

	local gobel = {};

	gobel.f = test;
	--	local f =loadstring("test()");
	gobel.__index = gobel;
	local f =loadstring("gobel.f()");
	f();

end

function switch(t)
  t.case = function (self,x)
    local f=self[x] or self.default
    if f then
      if type(f)=="function" then
        f(x,self)
      else
        error("case "..tostring(x).." not a function")
      end
    end
  end
  return t
end

a = switch {
  [1] = function (x) print(x,10) end,
  [2] = function (x) print(x,20) end,
  default = function (x) print(x,0) end,
}

a:case(2);
a:case(9);
--main()
