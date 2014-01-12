#!/usr/bin/env python
import optparse
import os

def main():
    u = optparse.OptionParser(
            description = 'Python clone of ls command. Prints out a list of files in a directory separated by newlines.',
            prog    = "ls.py",
            version     = "1.0rc",
            usage       = "%prog [directory]"
            )
    (options, arguments) = u.parse_args()
    if len(arguments) == 1:
        path = arguments[0]
        for filename in os.listdir(path):
            print filename
    else:
        u.print_help()


if __name__ == '__main__':
    main()
