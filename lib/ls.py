#!/usr/bin/env python
import optparse
import os
import sys

optarg = optparse.OptionParser(
        description = 'Python clone of ls command. Prints out a list of files in a directory separated by newlines.',
        prog        = "ls.py",
        version     = "1.2rc",
        usage       = "%prog [directory]"
        )
optarg.add_option('-f', '--filetype', help='selects specific filetype extensions')
(options, arguments) = optarg.parse_args()

def main():
    if len(arguments) == 1:
        path = arguments[0]
        filetype, filenames = options.filetype, os.listdir(path)
        if filetype is not None:
            filenames = [
                name for name in filenames if name.endswith(tuple(filetype))
                ]
        for file in filenames:
            sys.stdout.write('%s\n' % file)
    else:
        optarg.print_help()
        sys.stderr.write('ls.py only takes 1 argument' + '\n')

if __name__ == '__main__':
    main()
