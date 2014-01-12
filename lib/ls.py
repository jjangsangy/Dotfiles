#!/usr/bin/env python
import optparse
import os

def main():
    u = optparse.OptionParser(
            description = 'Python clone of ls command. Prints out a list of files in a directory separated by newlines.',
            prog        = "ls.py",
            version     = "1.1rc",
            usage       = "%prog [directory]"
            )
    (options, arguments) = u.parse_args()
    path = arguments[0]
    if len(arguments) == 1:
        for pathname in os.listdir(path):
            print pathname
    elif len(arguments) == 2:
        from glob import glob
        filetype = arguments[1]
        for pathname in glob(os.path.join(path,'*')+filetype):
            filename = pathname.split('/')[-1]
            print filename.split('.'+filetype)[0]
    else:
        u.print_help()


if __name__ == '__main__':
    main()
