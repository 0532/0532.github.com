---
layout: post
title: ��η���node.js��
description: Github������ǲ���Ĵ�����������Ҳ�ṩ��һЩ�����ķ��񣬱���Github Pages��ʹ�������Ժܷ���Ľ����Լ��Ķ������ͣ�������ѡ�
category: blog
---

[npm][1] ���Էǳ�����ط���һ�������� [pip][5]��[gem][4]��[pear][3] Ҫ�򵥵öࡣ�ڷ���֮ǰ������
��Ҫ�����ǵİ����� [npm][1] �Ĺ淶��[npm][1] ��һ���� [CommonJS][2] Ϊ�������淶������ CommonJS
������ȫһ�£�����Ҫ������ڱ����ֶεĲ�ͬ��ͨ��ʹ�� `npm init` ���Ը��ݽ���ʽ�ʴ�
����һ�����ϱ�׼�� package.json�����紴��һ����Ϊ wanglichao ��Ŀ¼��Ȼ�������
Ŀ¼�����У�

		$ npm init
		$ Package name: (wanglichao) wanglichao
		$ Description: A module for learning perpose.
		$ Package version: (0.0.0) 0.0.1
		$ Project homepage: (none) http://0532.github.com/
		$ Project git repository: (none)
		$ Author name: wanglichao
		$ Author email: (none) wanglichao@163.com
		$ Author url: (none) http://0532.github.com/
		$ Main module/entry point: (none)
		$ Test command: (none)
		$ What versions of node does it run on? (~0.6.10)
		$ About to write to /home/wanglichao/wanglichao/package.json
		$ {
		$ "author": "wanglichao <wanglichao@163.com> (http://0532.github.com/)",
		$ "name": "wanglichaomodule",
		$ "description": "A module for learning perpose.",
		$ "version": "0.0.1",
		$ "homepage": "http://0532.github.com/",
		$ "repository": {
		$ "url": ""
		$ },
		$ "engines": {
		$ "node": "~0.6.12"
		$ },
		$ "dependencies": {},
		$ "devDependencies": {}
		$ }
		$ Is this ok? (yes) yes
		
�������� `wanglichao`Ŀ¼������һ������ [npm][1] �淶�� package.json �ļ�������һ��
index.js ��Ϊ���Ľӿڣ�һ���򵥵İ�����������ˡ�
  �ڷ���ǰ�����ǻ���Ҫ���һ���˺����ڽ��ά���Լ��İ���ʹ�� `npm adduser` ����
��ʾ�����û��������롢���䣬�ȴ��˺Ŵ�����ɡ���ɺ����ʹ�� `npm whoami` ������
���Ѿ�ȡ�����˺š�
  ���������� package.json ����Ŀ¼������ `npm publish`���Ե�Ƭ�̾Ϳ�����ɷ����ˡ�
������������� [http://search.npmjs.org/][6] �Ϳ����ҵ��Լ��ոշ����İ��ˡ��������ǿ�����
���������һ̨�������ʹ�� `npm install wanglichao` ��������װ����ͼ3-6 ��npmjs.
org�ϰ�������ҳ�档
  �����İ������и��£�ֻ��Ҫ�� package.json �ļ����޸� version �ֶΣ�Ȼ������
ʹ�� `npm publish` ��������ˡ��������ѷ����İ������⣨�������Ƿ��������������
��İ���������ʹ�� `npm unpublish` ������ȡ��������
		
[1]: https://www.npmjs.org/		
[2]: http://wiki.commonjs.org/wiki/Modules/1.1
[3]: http://pear.php.net/
[4]: http://rubygems.org/pages/download
[5]: https://pypi.python.org/pypi/pip/
[6]: http://search.npmjs.org/