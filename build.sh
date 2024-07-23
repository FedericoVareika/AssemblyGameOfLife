#!/bin/bash

filename=$1
as -o $filename.o $filename.s
ld -o $filename $filename.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _start -arch arm64
