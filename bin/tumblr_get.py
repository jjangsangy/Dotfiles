#!/usr/bin/env python3

import requests
import sys
import os
import json

keyfile = '/'.join([os.getenv(HOME), 'Dropbox/sites/api_key.key'])
with open(keyfile) as key:
    API_KEY = key.read()

def data_session(user, *methods):
    s = requests.Session()
    s.params = {'api_key': API_KEY}
    url = '/'.join(
            ['http://api.tumblr.com/v2/blog/'+user+'.tumblr.com'] +
            list(methods))
    return s.get(url)

def retrieve_blog():
    try:
        blog = data_session('jjangsangy', 'posts')
        if not blog.ok: response.raise_for_status()
    except requests.exceptions.RequestException as e:
        print('Connection Error:', e)
        return

    posts = blog.json()['response']['posts']
    for post in posts:
        tags = (
            _title = post['title'],
            _type = post['type'],
            _date = post['date'],
            _slug = post['slug'],
            _tags = post['tags'],
            _body = post['body'])

        if 'photo' in _type:
            for photo in post['photos']:
                _photo = photo['original_size']['url']

        with open('{}.rst'.format(_slug), 'wt') as blogpost:
            for tag in tags:
                blogpost.write('')


def main():
    req = request('6OSb6dys8qgNphqWpSpizc4o8ht3Go7DkYkgUK6RYiQ610IIVY', 'posts', 'photo')
    for post in req['response']['posts']:
        print(post['slug'])
        for photo in [original for original in post['photos']]:
            print(photo['original_size']['url'])
    print('\n')

def getrequest():


if __name__ == '__main__':
    main()
