#/usr/bin/env python
import platform


profile = [
        platform.architecture(),
        platform.dist(),
        platform.libc_ver(),
        platform.mac_ver(),
        platform.machine(),
        platform.node(),
        platform.processor(),
        platform.python_build(),
        platform.system(),
        platform.uname(),
        platform.version(),
        ]

for item in profile:
    print item
