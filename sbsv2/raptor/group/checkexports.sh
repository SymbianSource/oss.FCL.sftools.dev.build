#!/bin/bash

for dir in . cpp-raptor cygwin-1.5.25 mingw-5.1.4 python-2.5.2; do
	echo testing exports.inf in $dir
	(cd $dir; ./exports.sh2; sort exports.inf > t1; sort exports.inf2 > t2; diff t1 t2)
done

