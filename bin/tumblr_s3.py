#!/usr/bin/env python3

import requests
import os
import sys
import json

def request(url):
    req = requests.get(url)
    if req.ok:
        return req

def main():
    with open(sys.argv[1]) as link_file:
        for line in link_file:
            response = requests.get(line.strip())
            filename = response.url.split('/')[4].split('?')[0]
            with open(filename, 'wb') as image:
                print("Downloading: {0}".format(filename))
                for chunk in response.iter_content(4096):
                    image.write(chunk)



if __name__ == '__main__':
    if sys.argv[1] and os.path.isfile(sys.argv[1]):
        sys.exit(main())
    else:
        raise IOException
        sys.stderr.write('%s error, file does not exist', e)
