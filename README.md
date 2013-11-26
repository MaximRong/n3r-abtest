n3r-abtest
==========

n3r-abtest������������ab����ʹ�õģ��ù���ʹ��lua�ű���д��Ƕ�뵽nginx��

��ʾ��:
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

��nginx����������"n3r.SplitFlow"������rotePage����(����Ϊ��ǰ��location name)�����ɷ��ض�Ӧ��ҳ��
����ѡ��ʹ��lua�ű���ת����Ӧҳ�棬Ҳ����ʹ��nginx������ת��

����Ҫ��:
---------

1. redis �ڴ����ݿ� ���ڼ�¼ab����������� download : [http://redis.io/](http://redis.io/)
2. nginx ������ ab������nginx������ת download : [http://nginx.org/en/download.html](http://nginx.org/en/download.html)
3. lua �ű����ԣ�ab���Ա�д���� (ע : �з�ʱʹ�õ���openresty�����������벿�����nginx֧��lua����) download : [http://openresty.org/](http://openresty.org/)
4. siege ѹ�����Թ��ߣ�ʹ�ü� download : [http://www.joedog.org/siege-home/](http://www.joedog.org/siege-home/)

�������:
---------

1. ��SplitFlow.lua�ű����뵽nginx���õ�lua���С�(����n3r�ļ�����)
2. ����nginx.conf 
   1). ��http�����server��������һ����ʼ�����ã������趨ȫ�ֱ�����
   ```nginx
	init_by_lua '
		abConfigCache = {};
		    ';
   ```
   2). �����ļ�˵�� (N3rSplitFlowConfig.lua)
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

   redisHost : redis��Ӧ��Host
   redisPort : redis��Ӧ��Port
   flowLimitRate : �����������������ʱ����������ҳ�������
   splitRules : ���ù��򣬿������ö�����򣬸��ݲ�ͬ��locationName������

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
   locationName ��Ӧkey�����ں������splitFlowʱ����Ҫ�õ�
   method �����ķ�������Ӧ��ip��flow��weight����
   testMode �Ƿ����ģʽ falseΪ�ǲ���ģʽ trueΪ����ģʽ
   rule ��Ӧ����:
   ʹ�ø���ip������method����Ϊ"ip"�� testMode�ǲ���ģʽ�Ƿ�򿪡�rule�Ƕ�Ӧ������һ��json�ַ�����
   rule json key Ϊ��ʼip-��ֹip �� ֵΪ��Ӧҳ�棬 ��ʼip��ַҪС����ֹip�� default key ������Ĭ����תҳ�档

   ʹ��Ȩ�ط�����methodΪ"weight"��rule ����Ϊ ��ӦȨ�� = ��Ӧҳ��, default��ӦĬ����תҳ��

   ʹ������������methodΪ"flow"��rule ����Ϊ �޶��������ʴ��� = ��Ӧҳ�棬 defaultΪ�������úõ��޶�������ת��Ĭ��ҳ�档

3. splitFlow.rotePage("localtionName") ��������÷��ض�Ӧ��תҳ�棬������lua ���� ngixn��ʵ����ת��

4. ���testModeΪ falseʱ�� ����������ģʽ�� ҳ����¼�û����ʼ�¼����Զ����֮ǰ��½��ҳ�棬���Ҳ���¼ͳ�����ݡ�

ѹ������:
-----------

1. ��SeigeResult.lua�ű����뵽nginx���õ�lua���С�(����n3r�ļ�����)

2. ��nginx.conf�м�����������:
   ```nginx
    location /SiegeResult {
            default_type text/html;
            content_by_lua '
				local seigeResult = require "n3r.SeigeResult";
				seigeResult.result();
            ';
        }
   ```

3. ����siege������Ҫ���Ե�ҳ�棬���� siege http://ip:port/abtest -c 5 -r 5

4. ���� http://ip:port/SiegeResult �鿴ѹ�����Խ����
   
> localName is : abtest 
> page	count
> html/three.html 29
> html/two.html 2