local _M = {
	_VERSION = '0.1'
}

_M.split = function()
	local pattern = "^(%d+%.%d+%.%d+%.%d+)%s*,*.*$";
--	return (x_forwarded_for:gsub(pattern, "%1"));
	ngx.var.x_forwarded_for = (ngx.var.x_forwarded_for:gsub(pattern, "%1"));
end;

return _M;