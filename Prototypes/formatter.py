from fileinput import filename
import os

path = os.getcwd() + '\\websites.txt'
print(path)

with open(path) as file:
    sites = file.readlines();

    for site in sites: 
        if site =='\n':
            continue
        site = ''.join(site.split())
        site = '\'' + site + '\','
        print(site)

