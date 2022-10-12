from flask import Flask
from flask import jsonify
from RecipeScraper.Recipe import Recipe
from bs4 import BeautifulSoup
from urllib.request import urlopen, Request
from urllib.parse import urljoin
from recipe_scrapers import scrape_me
from multiprocessing.dummy import Pool
from multiprocessing import cpu_count
from concurrent.futures import ThreadPoolExecutor
import concurrent.futures
import py_eureka_client.eureka_client as eureka_client
import tqdm

your_rest_server_port = 5000
# The flowing code will register your server to eureka server and also start to send heartbeat every 30 seconds
eureka_client.init(eureka_server="http://eureka:8761/eureka/",
                app_name="Scraper",
                instance_port=your_rest_server_port)

app = Flask(__name__)
searchTerm = ''

@app.route("/")
def hello_world():
    return "Hello, World!"

@app.route("/<search>")
def startScrape(search):

    searchTerm = search
    urls = getUrls(searchTerm)
    
    with Pool(processes=cpu_count()*2) as pool, tqdm.tqdm(total=len(urls)) as pbar:
        recipes = []
        for data in pool.imap_unordered(ScrapeSite, urls):     # send urls from all_urls list to parse() function (it will be done concurently in process pool). The results returned will be unordered (returned when they are available, without waiting for other processes)
            recipes.extend(data)                                           # update all_data list
            pbar.update() 

    # for recipe in recipes:
    #     print(recipe)
    return jsonify(recipes)


def ScrapeSite(url):
    req = Request(url , headers={'User-Agent': 'Mozilla/5.0'})
    try:
        page = urlopen(req).read()
    except:
        return

    recipes = []
    soup = BeautifulSoup(page, 'html.parser')

    search = set(soup.select(f'a[href*="{searchTerm}"]'))
    with ThreadPoolExecutor() as t:
        futures = []
        for recipe in search:
            recipeUrl = recipe.get('href')
            recipeUrl = urljoin(url, recipeUrl)
            print(f'{recipeUrl}\n')
            futures.append(t.submit(ScrapeRecipe, recipeUrl))
        for future in concurrent.futures.as_completed(futures):
            #print(future.result())
            if future.result():
                recipes.append(future.result())
    return recipes

def ScrapeRecipe(recipeUrl):
    # print(recipeUrl)
    # print(f"{url}  {search.get('href')}\n")
    # recipe = search.get('href')

    try:
        scraper = scrape_me(recipeUrl)
        # print(scraper.title())
        # print(scraper.total_time())
        # print(scraper.yields())
        # print(scraper.ingredients())
        # print(scraper.instructions_list())  # or alternatively for results as a Python list: scraper.instructions_list()
        # print(scraper.image())
        # scraper.host()
        # scraper.links()
        # scraper.nutrients()

        # scrapedRecipe = Recipe(recipe, scraper.title, scraper.author, scraper.total_time, scraper.yields, 
        #     scraper.ingredients, scraper.instructions_list, scraper.image)
        # print(scrapedRecipe)

        title = scraper.title()
        author = scraper.author()
        time = scraper.total_time()
        yields = scraper.yields()
        ingredients = scraper.ingredients()
        instructions = scraper.instructions_list()
        image = scraper.image()

        scrapedRecipe = Recipe(recipeUrl, title, author, time, yields, 
            ingredients, instructions, image)
        #print('yo')
        return scrapedRecipe.Serialize()
    except:
        #print(e.__class__)
        return

def getUrls(searchTerm):
    urls = [f'https://www.allrecipes.com/search?q={searchTerm}',
    f'https://www.mybakingaddiction.com/?s={searchTerm}',
    f'https://sallysbakingaddiction.com/?s={searchTerm}',
    f'https://tastesbetterfromscratch.com/?s={searchTerm}',
    f'https://www.food.com/search/{searchTerm}',
    f'https://www.bonappetit.com/search?q={searchTerm}']

    return urls