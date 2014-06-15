#!/usr/bin/env python3

from pygments import sys
import os


def main():
    if not sys.stdin.isatty():
        line = (line.split() for line in sys.stdin)
        for word in line:
            for letter in word:
                if letter.isupper():
                    print(letter)

str.isupper

if __name__ == '__main__':
    sys.exit(main())
