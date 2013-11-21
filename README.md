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
   2). 在对应需要使用ab测试的location 中配置lua脚本，实现方式可以参照上面的示例。
       在retePage中传入的参数为当前的location name
   
   3). 配置redis,在redis中增加ab测试对应的key,目前支持三种配置，分别是根据ip分流、根据权重分流、根据流量分流，三种配置示例如下：
    根据ip分流配置
   ```redis
	{
	  "method": "ip",
	  "testMode": "false",
	  "rule": "{\"192.168.0.1-192.168.2.1\":\"html/one.html\",\"192.168.126.4-192.168.126.5\":\"html/two.html\",\"default\":\"html/three.html\"}"
	}
   ```
   使用根据ip分流，method必须为"ip"， testMode是测试模式是否打开。rule是对应规则，是一个json字符串。
   rule json key 为起始ip-终止ip ， 值为对应页面， 起始ip地址要小于终止ip。 default key 是配置默认跳转页面。

    根据权重分流配置
   ```redis
	{
	  "method": "weight",
	  "testMode": "false",
	  "rule": "{\"1\":\"html/one.html\",\"2\":\"html/two.html\",\"3\":\"html/three.html\"}"
	}
   ```
   使用权重分流，method为"weight"，rule 配置为 对应权重 ： 对应页面。

    根据流量分流配置
   ```redis
	{
	  "method": "flow",
	  "testMode": "false",
	  "rule": "{\"2\":\"html/two.html\",\"default\":\"html/three.html\"}"
	}
   ```
   使用流量分流，method为"flow"，rule 配置为 限定流量访问次数 ： 对应页面， default为超过设置好的限定流量跳转的默认页面。