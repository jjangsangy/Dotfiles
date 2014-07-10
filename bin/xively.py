#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import print_function, unicode_literals

import sys
import os
import json
import datetime
import dateutil.parser
from argparse import ArgumentParser

from functools import wraps

import requests

API_KEY = "3uRrLcI9fvzrCEyp8reyGDDQLj4ZThQNhzfoiQXA7mIdVacZ"
FEED_ID = 1323604224

def connect(limit, interval, duration, filetype):
#   start = datetime.datetime.isoformat(datetime.datetime.now() - datetime.timedelta(hours=12))
    base = "https://api.xively.com/v2/feeds"
    headers = {"X-ApiKey": API_KEY,
               "Host": "api.xively.com",
               "Content-Encoding": "utf-8,gzip"}
    params = {"duration": duration,
              "interval": interval,
              "limit": limit}
    url = "/".join([base, str(FEED_ID)])
    request = requests.get(
            ".".join([url, filetype]),
            headers=headers,
            params=params)
    return request

def main():
    parser = ArgumentParser()
    parser.add_argument('-v', '--version', action='version', version='0.0.1')
    # parser.add_argument('stream', nargs='?', help='Grab a feed datastream')
    parser.add_argument('--limit', metavar='lim', default='100',
                        help='Default: 100, Max: 1000')
    parser.add_argument('--filetype', default='csv',
                        metavar='ft', help='Default: csv',
                        choices=('json', 'csv', 'xml'))
    parser.add_argument('--duration', default='12hours',
                        metavar='time',
                        help='Default: 6hours')
    parser.add_argument('--interval', default=60, metavar='rep')
    args = parser.parse_args()

    request = connect(args.limit, args.interval, args.duration, args.filetype)

    if request.ok:
        points = (data.split(',') for data in request.text.split('\n'))
        for point in points:
            print('{0:8} {1:10}'.format(point[2]+'F', point[0]), dateutil.parser.parse(point[1].replace('T', ' ')).ctime())
    elif request.status_code != requests.codes.ok:
        return request.raise_for_status()
    else:
        return 'Program failed to execute'

if __name__ == '__main__':
    sys.exit(main())
