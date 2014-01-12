#!/usr/bin/env python
import platform


profile = [
        platform.architecture(),
        platform.dist(),
        platform.libc_ver(),
        ]

for item in profile:
    print item
