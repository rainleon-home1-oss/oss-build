# Github 发布

## Travis github releases uploading

-------

### 配置示例

    deploy:
      provider: releases
      api_key: "GITHUB OAUTH TOKEN"
      file:
        - "target/oss-configlint-1.0.6.OSS-SNAPSHOT.jar"
      skip_cleanup: true
      on:
        tags: true
        all_branches: true

- 确保 `skip_cleanup: true` ,否则travis CI会删除构建产物
- 加密token有两种方式，一种是在setting界面来配置token，一种是指定secure的token: `api_key:
        secure: XXXXXXX`
- `all_branches: true` 来描述在所有分支的tag来做deploy，配置不正确会印发异常:
    `Skipping a deployment with the releases provider because this branch is not permitted`，详细参见[issues-1675](https://github.com/travis-ci/travis-ci/issues/1675)
- 如果想用通配符指定多个目录，需要增加 `file_glob: true` ,然后`file: dir1/*`
- 使用 `before_deploy` 和 `after_deploy`来扩展deploy的前后的准备和清理工作
- 定制deploy条件，可参照下面的内容。

-------

### 触发机制
1. 本地执行 `git tag v1.0.1` 然后 `git push origin tag_name`会触发一次travis ci的构建
2. 或者在github的release标签页，新建release。

### Conditional Releases with `on:`

通用的条件如下:

1. `repo` 描述仓库的区块:(owner_name/repo_name,e.g,test/hello-world)
2. `branch` 分支的名称，如果不指定，默认是app- 或者是master分支。若不确定哪些分支可以做release操作，可以指定`all_branch:true`实现 `branch: **`，可以同时和其他条件配合使用
3. `jdk, node, perl, php, python, ruby, scala, go` 用来指定不通语言的多版本。
4. `condition`用来设定bash的条件，必须是一个字符串，会被传递到bash的表达式，形如：`if [[ <condition> ]]; then <deploy>; fi`,条件可以很复杂，但是只能有一个条件。如`$CC = gcc`
5. `tags` 当指定为true，将会在一个tag被应用到提交时触发deploy，这会导致`branch`条件被忽略，

## 发布模型


### Gitflow
#### 发布版本(release)

从develop分支创建release分支, 使用release版本号更新pom(s)

    # 确保没有未提交的修改
    mvn gitflow:release-start
    # 检查所有出现版本号的位置是否被正确修改

将release分支merge到master, 使用develop版本号更新pom(s), 将release分支merge到develop, 删除release分支

    # 可选的 mvn clean install [deploy]
    # 确保全部测试通过, 否则无法release-finish
    mvn gitflow:release-finish
    # 检查所有出现版本号的位置是否被正确修改
    git push origin develop:develop
    # 可选的 触发ci发布新版本
    git push origin master:master
    # 可选的 触发ci发布新版本

#### 紧急修复一个bug(hotfix)

从master分支创建hotfix分支, 使用hotfix版本号更新pom(s)

    # 确保没有未提交的修改
    mvn gitflow:hotfix-start
    # 检查所有出现版本号的位置是否被正确修改
    # 进行开发
    # 提交所有未提交的修改

将hotfix分支merge到master, 使用之前的版本号更新pom(s) 这里有问题下文详述, 将hotfix分支merge到develop 这里有问题下文详述, 删除hotfix分支

    # 可选的 mvn clean install [deploy]
    mvn gitflow:hotfix-finish
    # 选择要完成的hotfix分支(可以同时有多个hotfix)
    # 会发生pom冲突或其它冲突
    # pom冲突主要是因为hotfix分支来自于master上最后一个release, develop分支的版本号在最后一个release之后增加了.
    # 详见issue: https://github.com/aleksandr-m/gitflow-maven-plugin/issues/19
    # 编写此文档时这个问题还没有解决办法
    # 手动处理冲突
    # 检查所有出现版本号的位置是否被正确修改
    # git add .
    # git commit -m 'resolve conflicts on merge'
    # git branch -d hotfix/<填写版本号>
    git push origin develop:develop
    # 可选的 触发ci发布新版本
    git push origin master:master
    # 可选的 触发ci发布新版本

#### 开发一个新功能(feature)

从develop分支创建feature分支, 使用之前的版本号更新pom(s), 可选择更新或不更新版本号, 默认使用feature名字更新版本号更新pom(s)

    # 确保没有未提交的修改
    mvn gitflow:feature-start
    # 输入feature名称
    # 检查所有出现版本号的位置是否被正确修改
    # 进行开发
    # 提交所有未提交的修改

将feature分支merge到develop分支, 使用之前的版本号更新pom(s), 删除feature分支

    mvn gitflow:feature-finish
    # 选择要完成的feature名称(可以同时有多个feature)
    # 检查所有出现版本号的位置是否被正确修改
    git push origin develop:develop
    # 可选的 触发ci发布新版本

### 发布流程操作步骤
1. 本地develop分支上执行 `mvn gitflow:release-start`, 新建release分支。检查版本号，是否生效;
2. push到远端，触发travis-ci的发布操作,publish到nexus仓库。nexus仓库发布仅在release分支上触发，其他分支屏蔽。这里如果第一次发布成功了，后面的发布，版本号需要往上迭代才可以再次发布，具体需要删除当前的release分支，重新执行步骤1，但是注意版本号需要升级。
3. nexus发布成功后，证明此次release代码OK。本地执行`mvn gitflow:release-finish`.本地的release分支会被删除，并新打出tag，
4. push tag到远端 `git push origin tag_name`，触发tag的发布，tag不做nexus的发布操作，只做test_and_build 和uploading release的产物，如工具类的jar到github。push之后，在github会产生一个release。
5. tag发布完毕后，再回到本地，进行善后清理操作，将develop和master的提交，推到远端，release分支的删除操作，也推到远端。


## 参考资料
- [Deployment](https://docs.travis-ci.com/user/deployment#Conditional-Releases-with-on%3A)
- [GitHub Releases Uploading](https://docs.travis-ci.com/user/deployment/releases/)
- [painless-maven-project-releases-with-maven-gitflow-plugin](http://george-stathis.com/2013/11/09/painless-maven-project-releases-with-maven-gitflow-plugin/)
- [maven-git-flow-plugin-for-better-releases](http://blogs.atlassian.com/2013/05/maven-git-flow-plugin-for-better-releases/)
- [git-flow插件官方网站](http://jgitflow.bitbucket.org/)
- [conflict-free-git-trees](https://stanfy.com/blog/conflict-free-git-trees-part-1/)
- [https://github.com/KimJejun/gitflow-maven-plugin](https://github.com/KimJejun/gitflow-maven-plugin)
- http://www.jianshu.com/p/814fb6606734




