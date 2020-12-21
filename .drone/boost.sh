#!/bin/bash

set -ex
export TRAVIS_BUILD_DIR=$(pwd)
export TRAVIS_BRANCH=$DRONE_BRANCH
export TRAVIS_OS_NAME=${DRONE_JOB_OS_NAME:-linux}
export VCS_COMMIT_ID=$DRONE_COMMIT
export GIT_COMMIT=$DRONE_COMMIT
export DRONE_CURRENT_BUILD_DIR=$(pwd)
export PATH=~/.local/bin:/usr/local/bin:$PATH

echo '==================================> BEFORE_INSTALL'

. .drone/before-install.sh

echo '==================================> INSTALL'

BOOST_BRANCH=develop && [ "$TRAVIS_BRANCH" == "master" ] && BOOST_BRANCH=master || true
cd ..
git clone -b $TRAVIS_BRANCH --depth 1 https://github.com/boostorg/boost.git boost-root
cd boost-root
git submodule update --init tools/build
git submodule update --init libs/config
git submodule update --init tools/boostdep
git submodule update --init libs/parameter_python
git submodule update --init tools/boost_install
git submodule update --init libs/headers
cp -r $TRAVIS_BUILD_DIR/* libs/parameter
python tools/boostdep/depinst/depinst.py parameter
./bootstrap.sh
./b2 headers

echo '==================================> BEFORE_SCRIPT'

. $DRONE_CURRENT_BUILD_DIR/.drone/before-script.sh

echo '==================================> SCRIPT'

echo "using $TOOLSET : : $COMPILER ;" > ~/user-config.jam
./b2 --verbose-test libs/config/test//config_info toolset=$TOOLSET cxxstd=$CXXSTD || true
cd libs/parameter/test
../../../b2 -j`(nproc || sysctl -n hw.ncpu) 2> /dev/null` toolset=$TOOLSET cxxstd=$CXXSTD $CXXSTD_DIALECT
cd ../../..

echo '==================================> AFTER_SUCCESS'

. $DRONE_CURRENT_BUILD_DIR/.drone/after-success.sh
