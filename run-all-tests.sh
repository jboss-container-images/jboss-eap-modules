#!/bin/bash

for testName in `find ./ -name *.bats`; do echo ${testName}; bats ${testName}; done

