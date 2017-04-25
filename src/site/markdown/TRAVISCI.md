
# Travis-ci

## install travis cli on mac

* see [travis.rb](https://github.com/travis-ci/travis.rb#installation)

    brew install ruby
    gem update --system
    gem install travis -v 1.8.8 --no-rdoc --no-ri
    travis version

## Deploying to Maven Repositories from Tavis CI

* see: [Deploying to Maven Repositories from Tavis CI](https://vzurczak.wordpress.com/2014/09/23/deploying-to-maven-repositories-from-tavis-ci/)

## Publishing a Maven Site to GitHub Pages with Travis-CI

* see: [Publishing a Maven Site to GitHub Pages with Travis-CI](https://blog.lanyonm.org/articles/2015/12/19/publish-maven-site-github-pages-travis-ci.html)


    travis encrypt GITHUB_GIT_SERVICE_TOKEN="${GITHUB_GIT_SERVICE_TOKEN}" --add env.global

## Environment variables

see: [Environment variables](https://docs.travis-ci.com/user/environment-variables/)

Variables in travis repo settings:

|name                    | usage                | note                                                      |
|------------------------|:--------------------:|:---------------------------------------------------------:|
|GITHUB_USERNAME         | for github maven site| Display value in build log                                |
|GITHUB_GIT_SERVICE_TOKEN| for github maven site| Not display value in build log                            |
|                        |                      |                                                           |
|MAVEN_CENTRAL_USER      | for deploy artifact  | Do not set on forked repo, Not display value in build log |
|MAVEN_CENTRAL_PASS      | for deploy artifact  | Do not set on forked repo, Not display value in build log |

## Note

    env:
      global:
      # refer ci-script and config from repo version ,ex master/develop/v1.0.8
      - OSS_BUILD_REF_BRANCH=develop
      # adapt with gitlab-ci
      - CI_BUILD_REF_NAME=$TRAVIS_BRANCH
      # or delete /etc/mavenrc
      - MAVEN_SKIP_RC=true
    # Skipping the Installation Step
    install: true


## deployment

    # v is refered to gitflow-maven-plugin:versionTagPrefix
    before_deploy:
      - export PROJECT_MAVEN_VERSION=${TRAVIS_TAG/v/}

    deploy:
      provider: releases
      api_key: $GITHUB_GIT_SERVICE_TOKEN
      file: "target/oss-configlint-${PROJECT_MAVEN_VERSION}.jar"
      skip_cleanup: true
      on:
        tag: true
        all_branches: true

    after_deploy:
      - echo "deploy finished!"
