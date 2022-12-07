from http import client
from pydoc import cli
from time import monotonic
from flask import Flask
from flask import Response
from flask import jsonify
from flask import stream_with_context, request
import json
from RecipeScraper.Recipe import Recipe
from bs4 import BeautifulSoup
from urllib.request import urlopen, Request
from urllib.parse import urljoin
from recipe_scrapers import scrape_me
from multiprocessing.dummy import Pool
from multiprocessing import cpu_count
from concurrent.futures import ThreadPoolExecutor
import py_eureka_client.eureka_client as eureka_client
import tqdm
import pymongo
from pymongo import MongoClient

your_rest_server_port = 5000
# The flowing code will register your server to eureka server and also start to send heartbeat every 30 seconds
eureka_client.init(eureka_server="http://eureka:8761/eureka/",
                app_name="Scraper",
                instance_port=your_rest_server_port)

app = Flask(__name__)
searchTerm = ""

client = MongoClient('mongodb+srv://MuteCoot:bgO0h2zvGhhsr7PH@foodie.oszd0t8.mongodb.net/?retryWrites=true&w=majority')
db = client['Foodie']
collection = db['Recipes']

@app.route("/")
def hello_world():
    return "Hello, World!"

@app.route("/<search>")
def startScrape(search):
    #global searchTerm
    #searchTerm = search.replace(" ","-")
    search = search.replace(" ", "%20")
    urls = getUrls(search)

    def generate():
        with Pool(processes=cpu_count()*2) as pool:
            recipeSites = []
            for data in pool.imap_unordered(GetSites, urls):
                recipeSites.extend(data)

            pbar = tqdm.tqdm(total=len(recipeSites))

            recipes = []
            for recipe in pool.imap_unordered(ScrapeSite, recipeSites):
                if recipe:
                    # print(recipe)
                    recipes.append(recipe)
                    yield json.dumps(recipe)
                pbar.update() 
            try:
                collection.insert_many(recipes, False)
            except:
                print("duplicate url")


    return generate(), {"Content-Type":"text/event-stream"}


def GetSites(url):
    req = Request(url , headers={'User-Agent': 'Mozilla/5.0'})
    try:
        page = urlopen(req).read()
    except:
        return

    recipes = set()
    soup = BeautifulSoup(page, 'html.parser')

    for search in set(soup.select(f'a[href*="{searchTerm}"]')):
        # print(searchTerm)
        recipe = search.get('href')

        if recipe.startswith('/'):
            recipe = urljoin(url, recipe)

        recipes.add(recipe)
        
    return recipes

def ScrapeSite(url):
    print(url)
    try:
            scraper = scrape_me(url)

            title = scraper.title()
            author = scraper.author()
            time = scraper.total_time()
            yields = scraper.yields()
            ingredients = scraper.ingredients()
            instructions = scraper.instructions_list()
            image = scraper.image()

            scrapedRecipe = Recipe(url, title, author, time, yields, 
                ingredients, instructions, image)

            return scrapedRecipe.Serialize()
    except:
        return

def getUrls(search):
    urls = [f'https://www.allrecipes.com/search?q={search}',
    f'https://www.mybakingaddiction.com/?s={search}',
    f'https://sallysbakingaddiction.com/?s={search}',
    f'https://tastesbetterfromscratch.com/?s={search}',
    f'https://www.foodnetwork.com/search/{search}',
    f'https://www.bonappetit.com/search?q={search}']

    return urls