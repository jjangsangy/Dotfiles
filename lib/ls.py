#!/usr/bin/env python
import optparse
import os
import log_conf, logging

def main():
    u = optparse.OptionParser(
            description = 'Python clone of ls command. Prints out a list of files in a directory separated by newlines.',
            prog        = "ls.py",
            version     = "1.1rc",
            usage       = "%prog [directory]"
            )
    u.add_option('-f', '--filetype', help='selects specific filetype extensions')
    (options, arguments) = u.parse_args()
    logging.debug('options are %s', options)
    logging.debug('arguments are %s', arguments)

    if len(arguments) == 1:
        path = arguments[0]
        if options.filetype is not None:
            filetype = options.filetype
        else:
            filetype = str()

        from glob import glob
        pathname = os.path.join(path,'*')
        for path in glob(pathname+filetype):
            filename = path.split('/')[-1]
            print filename
    else:
        u.print_help()


if __name__ == '__main__':
    log_conf.setup_logging()
    main()
