#!/bin/bash
# This shell script just runs the tests coded in test/notification_test.rb
# The test cases written in that class are intended as self-documented cases,
# each of which has a verbose name stating what it tests.
bundler exec ruby tests/notification_test.rb
