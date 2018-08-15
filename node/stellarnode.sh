#!/bin/bash

# Dependencies
mkdir stellarnode && cd stellarnode
apt -qq update && apt -qq upgrade
apt -qq install pkg-config bison flex libpq-dev pandoc perl libtool libstdc++6 autoconf automake git build-essential
mkdir tmp && cd tmp
wget http://security.debian.org/debian-security/pool/updates/main/p/postgresql-9.6/libpq5_9.6.10-0+deb9u1_amd64.deb -qq
sudo dpkg -i *
cd .. && rm -rf tmp
apt -qq --fix-broken install
echo "deb http://ftp.fr.debian.org/debian unstable main contrib non-free" >> /etc/apt/sources.list
apt -qq update
apt -qq install gcc-5/unstable
apt -qq install g++-5/unstable
cat /etc/apt/sources.list |grep -v "$(tail -n 1 /etc/apt/sources.list)" > /etc/apt/sources.list
apt -qq update

# Regex from https://github.com/semver/semver/issues/232
reg='^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*)?(\+[0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*)?$'

echo "Fetching the sources.."
git clone https://github.com/stellar/stellar-core -q
cd stellar-core/

echo "Which version do you want to build ? (default : 9.2.0)"
read version
if ! [[ $version =~ $reg ]] ; then
	version='9.2.0'
fi
echo "Fetching v$version"
git checkout v$version  &>/dev/null
git submodule init &>/dev/null
git submodule update &>/dev/null
clear

echo "Configuring.."
./autogen.sh &>/dev/null
./configure CXX=g++-5 &>/dev/null
clear

echo "Building.."
make -j 2 &>makeOut
if ! [[ "$makeOut" =~ "Error" ]]; then 
        echo "Succesfully compiled"
	echo "Running the tests.."
	make check &>testsOut
	if grep -Fxq "All tests passed" $testsOut ; then
		echo "All tests passed"
		sudo make install
	else
		echo "One test did not pass"
	fi 
else
	echo "An error occured while compiling"
fi
