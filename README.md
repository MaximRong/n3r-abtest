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
   2). �ڶ�Ӧ��Ҫʹ��ab���Ե�location ������lua�ű���ʵ�ַ�ʽ���Բ��������ʾ����
       ��retePage�д���Ĳ���Ϊ��ǰ��location name
   
   3). ����redis,��redis������ab���Զ�Ӧ��key,Ŀǰ֧���������ã��ֱ��Ǹ���ip����������Ȩ�ط���������������������������ʾ�����£�
    ����ip��������
   ```redis
	{
	  "method": "ip",
	  "testMode": "false",
	  "rule": "{\"192.168.0.1-192.168.2.1\":\"html/one.html\",\"192.168.126.4-192.168.126.5\":\"html/two.html\",\"default\":\"html/three.html\"}"
	}
   ```
   ʹ�ø���ip������method����Ϊ"ip"�� testMode�ǲ���ģʽ�Ƿ�򿪡�rule�Ƕ�Ӧ������һ��json�ַ�����
   rule json key Ϊ��ʼip-��ֹip �� ֵΪ��Ӧҳ�棬 ��ʼip��ַҪС����ֹip�� default key ������Ĭ����תҳ�档

    ����Ȩ�ط�������
   ```redis
	{
	  "method": "weight",
	  "testMode": "false",
	  "rule": "{\"1\":\"html/one.html\",\"2\":\"html/two.html\",\"3\":\"html/three.html\"}"
	}
   ```
   ʹ��Ȩ�ط�����methodΪ"weight"��rule ����Ϊ ��ӦȨ�� �� ��Ӧҳ�档

    ����������������
   ```redis
	{
	  "method": "flow",
	  "testMode": "false",
	  "rule": "{\"2\":\"html/two.html\",\"default\":\"html/three.html\"}"
	}
   ```
   ʹ������������methodΪ"flow"��rule ����Ϊ �޶��������ʴ��� �� ��Ӧҳ�棬 defaultΪ�������úõ��޶�������ת��Ĭ��ҳ�档