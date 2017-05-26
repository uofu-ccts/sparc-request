#!/bin/bash

find /Volumes/HD2/projects/uofu/sparc-request/tmp -type f -name '*test-results' -mtime +3 -exec rm -f {} \;

