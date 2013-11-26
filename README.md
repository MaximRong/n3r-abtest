n3r-abtest
==========

n3r-abtest工程是用来做ab测试使用的，该工程使用lua脚本编写，嵌入到nginx。

简单示例:
---------

```nginx
   location /abtest {

    #content_by_lua_file conf/abcontroler.lua;
		content_by_lua '
		   ngx.header.content_type = "text/plain";
		   local splitFlow = require "n3r.SplitFlow";
		   local redirect = splitFlow.rotePage("abtest");
		   ngx.redirect(redirect);
		';
   }
```

在nginx配置中引入"n3r.SplitFlow"，调用rotePage方法(参数为当前的location name)，即可返回对应的页面
可以选择使用lua脚本跳转到对应页面，也可以使用nginx自行跳转。

环境要求:
---------

1. redis 内存数据库 用于记录ab测试相关配置 download : [http://redis.io/](http://redis.io/)
2. nginx 服务器 ab测试在nginx层做跳转 download : [http://nginx.org/en/download.html](http://nginx.org/en/download.html)
3. lua 脚本语言，ab测试编写语言 (注 : 研发时使用的是openresty，配置上线请部署相关nginx支持lua环境) download : [http://openresty.org/](http://openresty.org/)
4. siege 压力测试工具，使用简单 download : [http://www.joedog.org/siege-home/](http://www.joedog.org/siege-home/)

部署介绍:
---------

1. 将SplitFlow.lua脚本放入到nginx配置的lua库中。(放在n3r文件夹下)
2. 配置nginx.conf 
   1). 在http里，所有server外面增加一个初始化配置，用于设定全局变量。
   ```nginx
	init_by_lua '
		abConfigCache = {};
		    ';
   ```
   2). 配置文件说明 (N3rSplitFlowConfig.lua)
   ```lua
	local _Config = {
	["redisHost"] = "127.0.0.1",
	["redisPort"] = 6379,
	["flowLimitRate"] = "30%",



	["splitRules"] = {
		-- locationName abtest rule
		{
			["locationName"] = "abtest",
			["method"] = "flow",
			["testMode"] = true,
			["rule"] = {
				["2"] = "html/two.html",
				["default"] = "html/three.html",
			}
		},

		-- flow Limit Config
		{
			["locationName"] = "flowLimitConfig",
			["method"] = "flow",
			["testMode"] = false,
			["rule"] = {
				["2"] = "html/two.html",
				["default"] = "html/three.html",
			}
		},

		-- weight Config
		{
			["locationName"] = "weightConfig",
			["method"] = "weight",
			["testMode"] = false,
			["rule"] = {
				["20%"] = "html/one.html",
				["40%"] = "html/two.html",
				["default"] = "html/three.html"
			}
		},

		-- ip Config
		{
			["locationName"] = "ipConfig",
			["method"] = "ip",
			["testMode"] = true,
			["rule"] = {
				["192.168.0.1-192.168.2.1"] = "html/one.html",
				["192.168.126.4-192.168.126.5"] = "html/two.html",
				["default"] = "html/three.html"
			}
		}
	}
}
   ```

   redisHost : redis对应的Host
   redisPort : redis对应的Port
   flowLimitRate : 如果规则是限流规则时，访问限流页面随机率
   splitRules : 配置规则，可以配置多个规则，根据不同的locationName来区分

   ```lua
   {
			["locationName"] = "abtest",
			["method"] = "flow",
			["testMode"] = true,
			["rule"] = {
				["2"] = "html/two.html",
				["default"] = "html/three.html",
			}
		}
   ```
   locationName 对应key名，在后面调用splitFlow时候需要用到
   method 分流的方法，对应有ip、flow、weight三种
   testMode 是否测试模式 false为非测试模式 true为测试模式
   rule 对应规则:
   使用根据ip分流，method必须为"ip"， testMode是测试模式是否打开。rule是对应规则，是一个json字符串。
   rule json key 为起始ip-终止ip ， 值为对应页面， 起始ip地址要小于终止ip。 default key 是配置默认跳转页面。

   使用权重分流，method为"weight"，rule 配置为 对应权重 = 对应页面, default对应默认跳转页面

   使用流量分流，method为"flow"，rule 配置为 限定流量访问次数 = 对应页面， default为超过设置好的限定流量跳转的默认页面。

3. splitFlow.rotePage("localtionName") 会根据配置返回对应跳转页面，可以再lua 或者 ngixn中实现跳转。

4. 如果testMode为 false时， 不启动测试模式， 页面会记录用户访问记录，永远访问之前登陆的页面，并且不记录统计数据。

压力测试:
-----------

1. 将SeigeResult.lua脚本放入到nginx配置的lua库中。(放在n3r文件夹下)

2. 在nginx.conf中加入如下配置:
   ```nginx
    location /SiegeResult {
            default_type text/html;
            content_by_lua '
				local seigeResult = require "n3r.SeigeResult";
				seigeResult.result();
            ';
        }
   ```

3. 调用siege访问需要测试的页面，比如 siege http://ip:port/abtest -c 5 -r 5

4. 调用 http://ip:port/SiegeResult 查看压力测试结果。
   
> localName is : abtest 
> page	count
> html/three.html 29
> html/two.html 2