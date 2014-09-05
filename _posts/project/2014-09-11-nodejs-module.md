---
layout: post
title: 如何发布node.js包
category: project
description: 希望更多的人加入nodejs
---

 [npm][1] 可以非常方便地发布一个包，比 [pip][5]、[gem][4]、[pear][3] 要简单得多。
在发布之前，首先需要让我们的包符合npm的规范，npm 有一套以[CommonJS][2]为基础包规范，但与CommonJS并不完全一致，
其主要差别在于必填字段的不同。通过使用
npminit可以根据交互式问答产生一个符合标准的package.json，
例如创建一个名为 wanglichao 的目录，然后在这个目录中运行：

	$ npm init
	Package name: (wanglichao) wanglichao
	Description: A module for learning perpose.
	Package version: (0.0.0) 0.0.1
	Project homepage: (none) http://0532.github.com/
	Project git repository: (none)
	Author name: wanglichao
	Author email: (none) wanglichao@163.com
	Author url: (none) http://0532.github.com/
	Main module/entry point: (none)
	Test command: (none)
	What versions of node does it run on? (~0.6.10)
	About to write to /home/node_modules/wanglichao/package.json
	{
	"author": "wanglichao <wanglichao@163.com> (http://0532.github.com/)",
	"name": "wanglichao",
	"description": "A module for learning perpose.",
	"version": "0.0.1",
	"homepage": "http://0532.github.com/",
	"repository": {
	"url": ""
	},
	"engines": {
	"node": "~0.6.12"
	},
	"dependencies": {},
	"devDependencies": {}
	}
	Is this ok? (yes) yes   
	
	
 这样就在`wanglichao`目录中生成一个符合[npm][1]规范的package.json文件。
创建一个index.js 作为包的接口，一个简单的包就制作完成了。在发布前，我们还需要获得一
个账号用于今后维护自己的包，使用`npm adduser`根据提示输入用户名、密码、邮箱，等待
账号创建完成。完成后可以使用`npm whoami`测验是否已经取得了账号。 

 
接下来，在package.json所在目录下运行`npm publish`，稍等片刻就可以完成发布了。
打开浏览器，访问[http://search.npmjs.org/][6]就可以找到自己刚刚发布的包了。现在我们可以在
世界的任意一台计算机上使用`npm install wanglichao`命令来安装它。图3-6 是npmjs.org上包的描述页面。 
 
 
如果你的包将来有更新，只需要在 package.json 文件中修改 version 字段，然后重新使用`npm publish`
命令就行了。如果你对已发布的包不满意（比如我们发布的这个毫无意义的包），可以使用`npm unpublish`命令来取消发布。 


[1]: https://www.npmjs.org/
[2]: http://wiki.commonjs.org/wiki/Modules/1.1
[3]: http://pear.php.net/
[4]: http://rubygems.org/pages/download
[5]: https://pypi.python.org/pypi/pip/
[6]: http://search.npmjs.org/
[7]: http://0532.github.io/