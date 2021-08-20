#!/usr/bin/env python3

import requests 
repo = 'TrinityCore/TrinityCore'

r = requests.get(f'https://api.github.com/repos/{repo}/releases')

for relnum, release in enumerate(r.json()):
  if 'TDB335' in release['tag_name'] and 'TDB 335.' in release['name']:
    asset = release['assets'][0]
    print(asset['browser_download_url'])
    break
