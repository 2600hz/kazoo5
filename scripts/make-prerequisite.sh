#!/bin/bash

# Prerequisites check for make

# Check git version
GIT_MAJOR_VERSION=2
if type git > /dev/null 2>&1; then
    MajorVersion=`git --version | awk '{print $3}' | awk -F'.' '{print $1}'`
    if [ $MajorVersion -ne $GIT_MAJOR_VERSION ]
    then
        echo "git major version ${GIT_MAJOR_VERSION} is required."
        exit 1
    fi
else
    echo "git is missing"
    exit 1
fi

MAKE_MAJOR_VERSION=4
INSTALL_VERSION=4.3
if type make > /dev/null 2>&1; then
    MakeMajorVersion=`make -v | head -n1 | awk '{print $3}' | awk -F'.' '{print $1}'`

    if [ $MakeMajorVersion -ne $MAKE_MAJOR_VERSION ]
    then
        if [ -n "${CIRCLECI}" ]; then
            mkdir tmp/
            pushd tmp
            wget http://ftp.gnu.org/gnu/make/make-${INSTALL_VERSION}.tar.gz
            tar xvf make-${INSTALL_VERSION}.tar.gz
            cd make-${INSTALL_VERSION}/
            ./configure
            make
            sudo make install
            popd
            sudo rm -rf tmp/
            echo "installed make ${INSTALL_VERSION}"
            exit 0
        else
            echo "make major version ${MAKE_MAJOR_VERSION} is required."
            exit 1
        fi
    fi
else
    echo "make is missing"
    exit 1
fi
