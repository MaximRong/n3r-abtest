n3r-abtest
==========

#####n3r-abtest工程是火箭队研发的用于ab测试模块。[点我了解ab测试](http://oldj.net/article/ab-testing-basic-concept/) 该程序使用lua语言编写，嵌入Nginx层使用。

简单示例:
---------

```nginx
   
   # 假设需要做ab测试的location为 abtest
   location /abtest {
   		#内容阶段使用lua执行
		content_by_lua '
		   ngx.header.content_type = "text/plain";
		   local splitFlow = require "n3r.SplitFlow";
		   local redirect = splitFlow.rotePage("abtest");
		   ngx.redirect(redirect);
		';
   }
```

- 在nginx配置中，设置content_by_lua， 表示使用lua来进行内容处理。
- 设置content_type为"text/plain"
- 调用lua require函数，引入n3r.SplitFlow脚本。(脚本需要放置在nginx对应的lua lib中)
- 调用splitFlow对应的rotePage方法，传入参数是"location"的名称。(PS : 其实这个是一个key 但为了统一规则就确定使用location名称作为key)
- rotePage方法返回对应的路由页面，调用nginx自带的redirect函数跳转至对应页面。


环境要求:
---------

1. redis 内存数据库 用于记录ab测试相关配置 download : [http://redis.io/](http://redis.io/)
2. nginx 服务器 download : [http://nginx.org/en/download.html](http://nginx.org/en/download.html)
3. lua 脚本语言，ab测试编写语言 (注 : 研发时使用的是openresty，如果没有使用openresty，则需要在nginx服务器上搭建支持lua的环境) download : [http://openresty.org/](http://openresty.org/)
4. siege 压力测试工具，使用简单 download : [http://www.joedog.org/siege-home/](http://www.joedog.org/siege-home/)

部署介绍:
---------

1. 下载整个n3r文件夹，将其放入到lua对应的lib中。

2. 配置nginx.conf 
   
   1). 在http里，所有server外面增加一个初始化配置，用于设定全局配置。
   ```nginx
	init_by_lua '
		local _Config = {
			redisHost = "127.0.0.1",
			redisPort = 6379,
			testMode = true,



			splitRules = {
				-- locationName abtest rule
				{
					locationName = "abtest",
					method = "flow",
					cookie = "$province, 11",
					
					flowLimitRate = "10%",
					rule = {
						[2] = "html/two.html",
						default = "html/three.html",
					}
				},

				-- flow Limit Config
				{
					locationName = "flowLimitConfig",
					method = "flow",
					flowLimitRate = "1%",
					rule = {
						[2] = "html/two.html",
						default = "html/three.html",
					}
				},

				-- weight Config
				{
					locationName = "weightConfig",
					method = "weight",
					rule = {
						"50% /app/mall-res/static A",
					        "50% /app/mall-res/staticAB B"
					}
				},

				-- ip Config
				{
					locationName = "ipConfig",
					method = "ip",
					rule = {
						["192.168.0.1-192.168.2.1"] = "html/one.html",
						["192.168.126.4-192.168.126.5"] = "html/two.html",
						default = "html/three.html"
					}
				},
				
				-- os Config
				{
					locationName = "osConfig",
					method = "os",
					rule = {
						"computer /app/mall-res/static A",
					         "phone /app/mall-res/staticAB B"
					}
				},
				
				-- nginx variable Config
				{
					locationName = "varConfig",
					method = "var",
					var = "province",
					rule = {
						["11"] = "html/one.html",
						["12"] = "html/two.html",
						default = "html/three.html"
					}
				}
			}
		}

		local SplitFlowInit = require "n3r.SplitFlowInit";
		abConfigCache = SplitFlowInit.init(_Config);
		';
   ```
   ##### 这一段的目的是为了初始化的时候加载一次配置文件，不需要每次请求时候都重新加载。

 + redisHost : redis对应的Host
 + redisPort : redis对应的Port
 + testMode  : 测试模式是否开启



  splitRules : 配置规则，可以同时配置多个规则，根据不同的locationName做区分。

   ```lua
	   {
				locationName = "abtest",
 				method = "flow",
				testMode = true,
				rule = {
					[2] = "html/two.html",
					default = "html/three.html",
				}
			},
   ```

    1). locationName 对应值为调用location的名称，我们统一用location名称来作一个配置的key名。 <br/>
    2). method 分流的方法，对应值有ip、flow、weight、os、var五种  <br/>
    4). rule 对应规则:  


   + 根据ip分流配置规则说明：
   ```lua
   			-- ip Config
			{
				locationName = "ipConfig",
				method = "ip",
				cookie = "$province, extra",
				rule = {
					["192.168.0.1-192.168.2.1"] = "html/one.html",
					["192.168.126.4-192.168.126.5"] = "html/two.html",
					default = "html/three.html"
				}
			}
	```
   1). method必须为"ip"。 <br/>
   3). rule是对应规则，是一个json字符串。<br/>
       key 为"起始ip-终止ip" ， 值为对应调转页面。(注意 ： 起始ip地址要小于终止ip地址)  default 是配置默认跳转页面。<br/>
   4). 当客户端访问ip在所配置的ip段之间，则跳转到所配置的对应页面。如果都不在则跳转到默认页面。<br/>
   5). cookie表示当cookie缓存可以自定义关键字，以$符号的关键字为nginx变量，多个关键字以逗号分隔。我们以上面的配置说明， cookie名 = localtionName + $province的值 + 11，假设province为11时，那么cookie的key为ipConfig11extra。

   + 根据weight(权重)分流配置规则说明：
   ```lua
   		-- weight Config
			{
				locationName = "weightConfig",
				method = "weight",
				rule = {
					["20%"] = "html/one.html",
					["40%"] = "html/two.html",
					default = "html/three.html"
				}
			}
   ```
   1). method必须为"weight" <br/>
   2). rule对应规则：<br/>
       权重百分比 = 对应页面，default为默认页面。<br/>
   3). 比如如上配置，客户端发起1000次访问，则有20%左右概率访问为html/one.html页面，有40%左右概率访问为html/two.html页面，剩余(default)40%左右概率访问html/three.html页面。


   + 根据flow(流量)分流配置规则说明：
   ```lua
   		-- flow Limit Config
			{
				locationName = "flowLimitConfig",
				method = "flow",
				flowLimitRate = "30%",
				rule = {
					[2] = "html/two.html",
					default = "html/three.html",
				}
			}
   ```
   1). method必须为"flow"<br/>
   2). rule对应规则：<br/>
       限流次数 = 对应页面，default为超过限流次数后的默认访问页面。<br/>
   3). 这里必须要提到另外一个全局配置<br/>
   flowLimitRate = "30%" (30%可以为任意分流概率百分比)<br/>
   4). 比如上面的配置 当客户端发起访问请求时，有30%概率跳转到限流页面html/two.html, 而且每次成功跳转则计数器+1， 当发现已经超过分流次数限制(2次)，则之后的所有请求都访问default配置的默认页面 html/three.html

   + 根据os(操作系统)分流配置规则说明：
   ```lua
   		-- os Config
		{
			locationName = "osConfig",
			method = "os",
			rule = {
				["Win 7"] = "html/one.html",
				["Mac"] = "html/two.html",
				default = "html/three.html"
			}
		}
   ```
   1). method必须为"os"<br/>
   2). rule对应规则：<br/>
       操作系统 = 对应页面，default为超过限流次数后的默认访问页面。<br/>
   3). 操作系统可选项为：Win 8\Win 7\Win Vista\Win XP\Win 2000\Win NT\Win Me\Win 98\Win 95\Win CE\Win Phone\iPod\iPod\iPhone\Mac\Android\Symbian\Linux\BlackBerry\Nokia <br/>
   4). 取用户访问的http_user_agent变量，判断对应操作系统和跳转页面，当找不到对应页面时跳转至默认访问页面。<br/>

   + 根据var(nginx变量)分流配置规则说明：
   ```lua
   		-- nginx variable Config
		{
			locationName = "varConfig",
			method = "var",
			var = "province",
			rule = {
				["11"] = "html/one.html",
				["12"] = "html/two.html",
				default = "html/three.html"
			}
		}
   ```
   1). method必须为"var"<br/>
   2). var 表示对应的nginx变量名
   3). rule对应规则：<br/>
   	   变量值 = 对应跳转页面，当找不到对应页面时跳转至默认访问页面。<br/>

4. 说明一下testMode(测试模式)作用 ： <br/>
    1). 当为false, 则代表测试模式关闭，那么cookie中会记录用户曾经访问过该location对应跳转页面，那么用户下一次再请求同一location时则会直接跳转到之间访问的页面。另外用户请求后不会记录相关的访问日志。<br/>
	2). 当为true，则代表测试模式打开，那么所有请求都将不记录cookie，用户每次访问都会重新根据规则匹配，有可能访问的不是同一页面。另外当每次用户请求后，都会记录相关访问日志。<br/>

设置跳转页面
--------------
1. 在nginx中，增加如下配置:
```nginx
   location /setCookie {
         default_type text/html;
         charset 'utf-8';
             content_by_lua '
                   local ABCookieSet = require "n3r.ABCookieSet";
                   ABCookieSet.set();
             ';
 
         }
```
访问 host:port/setCookie 就能看到页面跳转设置页，再此页设置后，对应的location只会跳到指定的页面(前提是testMode必须为false)。

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

4. 调用 http://ip:port/SiegeResult 查看压力测试结果：
   
> localName is : abtest <br/>
> page	count <br/>
> html/three.html 29 <br/>
> html/two.html 2 <br/>
 

 测试用例:
-----------

在源代码中test文件对应的是测试用例，由于测试用例不是重点，所以简单说明一下。<br/>
测试用例使用的是busted框架，它是一个lua测试用例框架。官方网站是：[http://olivinelabs.com/busted/](http://olivinelabs.com/busted/)<br/>
并且需要在本机配置luaRocks，这是一个lua对应的中心仓库，通过它才能安装busted。官方网站是: [http://luarocks.org/](http://luarocks.org/)<br/>
如果你本地环境是5.2，那么请自行编译cjson.so文件，openresty自带的cjson.so对应执行环境是5.1，因此在执行测试用例时会报不兼容。<br/>

 修改历史:
-----------
##### 2013-12-24 ：

1. 提交cookie可动态设置名称<br/>
2. 剔除N3rSplitFlowConfig, 所有配置转移到nginx.conf中<br/>
3. 增加根据nginx变量分流规则<br/>
4. cookie增加超时时间<br/>
5. 优化配置语法<br/>


##### 2014-1-8 :
1. 增加一个固定设置跳转页面
2. 提供一个全局跳转后的cookie cookie名为 ： n3ABresult

#### 2014-2-10
1. 提交weight和os新的代码
2. 配置方式改变
3. 提供加密cookie
4. 废止ip flow var配置