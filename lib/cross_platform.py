#/usr/bin/env python
import platform as pl

profile = dict()
profile = {
        'Architecture': pl.architecture(),
        'Dist': pl.dist(),
        'LibC': pl.libc_ver(),
        'MacVersion': pl.mac_ver(),
        'Machine': pl.machine(),
        'Node': pl.node(),
        'Processor': pl.processor(),
        'PythonBuild': pl.python_build(),
        'System': pl.system(),
        'Version': pl.version()
        }

if __name__ == '__main__':
    for item in profile:
        if type(profile[item]) is str:
            print "%s: %s" % (item, profile[item])
        elif type(profile[item]) is tuple:
            for tup_item in profile[item]:
                if tup_item != '' and type(tup_item) != tuple:
                    print str(item)+": "+str(tup_item)
