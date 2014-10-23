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

from itertools import chain
from argparse import ArgumentParser, FileType

def printout(config):
    """
    Print out to stdout a list of methods and files associated with
    the methods set out in the configuration file.
    """
    for key, method in config.iteritems():
        print('[{key}]'.format(key=key))
        for directory, items in method.iteritems():
            print(
                '\t{path}'.format(path='\n\t'.join(items))
            )
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


def main():
    dotfiles = command_line()
    locations = (
        map(lambda f: os.sep.join([directory, f]), files)
            for directory, files in dotfiles.iteritems()
    )
    for i in chain.from_iterable(locations):
        print(os.path.abspath(i))

    return

if __name__ == '__main__':
    sys.exit(main())
