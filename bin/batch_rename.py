#!/usr/bin/env python
"""Work in web scraper"""
import requests
from bs4 import BeautifulSoup

import os
import sys

def query_site(video):
    url = 'http://actionjav.com/results.cfm'
    headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:31.0) Gecko/20100101 Firefox/31.0'}
    payload = {
        'go.x':0,
        'go.y':0,
        'video_title': video
    }
    response = requests.post(url, headers=headers, data=payload)

    if response.ok:
        try:
            soup = BeautifulSoup(response.text)
            return soup.find('span', attrs={"style": "background-color:yellow"}, text=video).find_next("p").text
        except:
            return None
    else:
        response.raise_for_status()

def batch_rename(directory):
    os.chdir(directory)
    vid_list = [vid.split('.')[0].split('_')[0] for vid in os.listdir('.') if vid.split('.')[0].split('_')[0].isdigit()]
    for vid in vid_list:
        for vid_file in os.listdir('.'):
            if vid_file.startswith(vid):
                new_name = query_site(vid)
                if new_name != None:
                    if vid_file.partition('_')[2].split('.')[0]:
                        os.renames(vid_file, new_name+'_'+vid_file.partition('_')[2].split('.')[0]+'.'+vid_file.split('.')[-1])
                    else:
                        os.renames(vid_file, new_name+'.'+vid_file.split('.')[-1])



def main():
    batch_rename(sys.argv[1])

if __name__ == '__main__':
    main()
