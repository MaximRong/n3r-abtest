local function main()

	local rule = {};
	rule['192.12.3.2-21.2.3.4'] = "one.html";
	rule['192.12.3.6-21.2.3.7'] = "two.html";
	
	
	local localConfig = {};
	localConfig['method'] = "ip";
	localConfig['rule'] = rule;
	print(localConfig);
	
end
main()
