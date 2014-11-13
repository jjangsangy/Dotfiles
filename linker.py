#!/usr/bin/env python
from __future__ import print_function, unicode_literals
"""
linker.py

Symbolically link your configuration files to your home directory.
Bootstrap and manage synchronization of your dotfiles.
"""

__author__  = 'Sang Han'
__title__   = 'linker'
__version__ = '0.0.0'
__release__ = 'test'

import os
import json
import sys
import string

from argparse import (
    ArgumentParser,
    FileType
)

from os.path import (
    expanduser,
    dirname,
    abspath,
    relpath,
    normpath,
    exists,
    isdir,
    isfile,
    samefile,
    expandvars,
)

HOME    = expandvars('$HOME')
PROGDIR = dirname(abspath(__file__))
GREEN, RED, RESET = '\033[32m', '\033[31m', '\033[0m'

def color_printer(message, color):
    green, RED, RESET = '\033[32m', '\033[31m', '\033[0m'
    cout = dict(('green', '\033[32m'), '('red', '\033[31m'))
    if not 'color' in expandvars('$TERM') or 'bash' in expandvars('$TERM'):
        return message
    sys.stdout.write()




def printout(config):
    """
    Print out to stdout a list of methods and files associated with
    the methods set out in the configuration file.
    """
    for key, method in config.iteritems():
        keys = '[{key}]'.format(key=key)
        print(keys)

        for directory, items in method.iteritems():
            output = '\t{path}'.format(path='\n\t'.join(items))
            print(output)

    return sys.exit(0)

def command_line():

    # Pre Process Configuration File
    pre_parser = ArgumentParser(add_help=False)

    pre_parser.add_argument(
        '--config',
        metavar='file',
        type=FileType('r'),
        default='link.json',
    )
    pre_parser.add_argument(
        '--list', '-l',
        action='store_true',
    )
    pre, _ = pre_parser.parse_known_args()
    config = json.load(pre.config)

    # List and Exit Point
    if pre.list:
        printout(config)

    # Main Parser
    parser = ArgumentParser(
        parents = [pre_parser],
        description="Symlink your dotfiles",
        prog=__title__
    )
    parser.add_argument(
        '--version',
        action='version',
        version=' '.join([__version__, __release__])
    )
    parser.add_argument(
        'method',
        nargs='?',
        choices=config.keys(),
        default='default',
    )

    args = parser.parse_args()

    return config[args.method]

def path_gen(mapping):
    for directory, files in mapping.iteritems():
        for f in files:
            f_path = os.sep.join([directory, f])
            yield relpath(normpath(f_path), start=PROGDIR)

def validator(filepath):
    dotted = ''.join([HOME, os.sep, '.', filepath.split(os.sep)[-1]])
    fullpath = abspath(filepath)
    GREEN, RED, RESET = '\032[32m', '\033[31m', '\033[0m'

    if not exists(filepath):
        message = string.Template('Missing:\n    - $RED$fullpath$RESET')
        print(message.substitute(vars()))
        return False

    if exists(dotted):
        message = string.Template("Collision:\n    - $dotted")
        print(message.substitute(vars()))
        return False

    if exists(filepath) and exists(dotted):
        if os.path.samefile(filepath, dotted):
            message = string.Template('Alredy Linked:\n    - $dotted')
            print(message.substitute(vars()))
            return False

    return dotted

def main():
    dotfiles = command_line()
    paths = path_gen(dotfiles)
    for path in paths:
        valid = validator(path)
        if valid:
            os.symlink(abspath(path), valid)
            linked = string.Template('Linked:\n    - $path, $valid')
            sys.stdout.write(GREEN)
            print(linked.substitute(vars()))
            sys.stdout.write(RESET)
    return


if __name__ == '__main__':
    sys.exit(main())
