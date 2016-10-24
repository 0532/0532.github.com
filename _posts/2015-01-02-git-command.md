---
layout: post
title: Git常用命令
---

{{ page.title }}
================

<p class="meta">02 Jan 2015 - 青岛</p>

**git配置（config）**

```
* git version
* git config -l
* git config --global user.name "Dean"
* git config --global user.email wanglichao@163.com
* git config --global alias.ci commit
* git config --global alias.co checkout
```

**git仓库（repository）**

```
# 创建一个本地的git仓库并命名：

* git init demo

# 克隆一个远程的git仓库到指定路径：
* git clone git@github.com/0532/daily.git /path/workspace
```
**git分支（branch)**

```
* git branch                   #查看分支
* git remote show origin       #查看所有分支
* git branch <branchname>      #创建分支
* git checkout <branchname>    #切换到分支
* git checkout -b <new_branch> #创建并切换到新分支
* git branch -d <branchname>   #删除分支（-D强删）
* git branch -m <old> <new>    #本地分支重命名
```

**git添加（add）**

```
* git add <file>      # 将本地指定文件名或目录（新增和修改，没有删除）的文件添加到暂存区
* git add .           # 将本地所有的（新增和修改，没有删除）文件添加到暂存区
* git add -u          # 将本地的（修改和删除，没有新增）文件添加到暂存区
* git add -A          # 将本地所有改动添加到暂存区（git add -A = git add . + * git add -u）
* git add -i          # 打开一个交互式界面按需求添加文件
```

**git删除/重命名（rm/mv）**

```
* git rm <file>                   # 删除文件
* git rm -r <floder>              # 删除文件夹
* git rm --cached <file>          #从版本库中删除文件，但不删除文件

* git mv <old_name> <new_name>    # 文件重命名

```

**git提交（commit）**

```
* git commit  -m "comment"           # 提交暂存区中的内容（已经add）并添加注释
* git commit -a                      # 把修改的文件添加到暂存区（不包括新建(untracked)的文件），然后提交。
* git commit --amend                 # 修改提交的commit（没有push）
* git commit --amend -m "comment"    # 修改commit注解
```

**git差异（diff）**

```
* git diff                     # 查看工作目录（working tree）暂存区（index）的差别
* git diff --cached            # 查看暂存起来的文件（stage）与并未提交（commit）的差别
* git diff --staged            # 同上
* git diff HEAD                # 查看最后一次提交之后的的差别（HEAD代表最近一次commit的信息）
* git diff --stat              # 查看显示简略结果(文件列表)
* git diff commit1 commit2     # 对比两次提交的内容（也可以是branch，哈希值）
```

**git查看历史（log）**

```
* git log
* git log -3           # 查看前3次修改
* git log --oneline    # 一行显示一条log
* git log -p           # 查看详细修改内容
* git log --stat       # 查看提交统计信息
* git log --graph      # 显示何时出现了分支和合并等信息
```

**git查看状态（status）**

```
* git status              # 查看你的代码在缓存与当前工作目录的状态
* git status -s           # 将结果以简短的形式输出
* git status --ignored    # 显示被忽略的文件
```

**git重置（reset）**

```
* git reset --mixed           # 同不带任何参数的git reset一样，重置暂存区，但不改变工作区
* git reset --soft            # 回退到某个版本，不改变暂存区和工作区（如果还要提交，直接commit即可）
* git reset --hard            # 彻底回退到某个版本，替换暂存区和工作区，本地的源码也会变为上一个版本的内容

* git reset                   # 将之前用git add命令添加到暂存区的内容撤出暂存区（相当于git add -A 的反向操作）
* git reset HEAD              # HEAD 效果同上，因为引用重置到HEAD相当与没有重置
* git reset filename          # 将文件撤出暂存区（相当于git add filename的反向操作）
* git reset HEAD^             # 引用回退一次（工作区不变，暂存区回退）
* git reset --soft HEAD~3     # 引用回退三次（工作区不变，暂存区不变）

```

**git撤销（revert）**

```
* git revert commit               # 撤销指定commit
* git revert HEAD                 # 撤销上一次commit
* git revert -no-edit HEAD        # 撤销上一次并直接使用默认注释
* git revert -n HEAD              # 撤销上一次但不commit

```

**git重新基变（rebase）**

```
* git rebase <branch_name>    #
* git rebase --continue       # 执行rebase出现冲突解决后，执行该命令会继续应用(apply)余下的补丁
* git rebase --skip           # 跳过当前提交
* git rebase --abort          # 终止rebase, 分支会回到rebase开始前的状态

```

**git获取/拉（fetch/pull）**

```
* git fetch origin master
* git fetch               # 从远程获取最新版本到本地，不会自动merge
* git pull                # 从远程获取最新版本并merge到本地
* git pull --rebase       # 暂存本地变更，合并远程最新改动，合并刚刚暂存的本地变更（不产生无用的merge的同步）

```

**git合并（merge）**

```
* git merge origin/master
* git merge <branch_name>             # 合并
* git merge --no-ff <branch_name>     # 采用no fast forward的合并方式，这种方式在合并的同时会生成一个新的commit
* git merge --abort                   # 尽量回退到merge前的状态（可能会失败）

```

**git推（push）**

```
* git push origin master      # 将本地分支推送到origin主机的master分支
* git push -u origin master   # -u指定origin为默认主机，后面就可以不加任何参数使用git push了
* git push -f origin          # -f强推，在远程主机产生一个"非直进式"的合并(non-fast-forward merge)
* git push --all origin       # 将所有本地分支都推送到origin主

```
