from flask import Flask
from flask import jsonify
from RecipeScraper.Recipe import Recipe
from bs4 import BeautifulSoup
from urllib.request import urlopen, Request
from recipe_scrapers import scrape_me
from multiprocessing.dummy import Pool
from multiprocessing import cpu_count
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

    for search in set(soup.select(f'a[href*="{searchTerm}"]')):
        print(f"{url}  {search.get('href')}\n")
        recipe = search.get('href')

        try:
            scraper = scrape_me(recipe)

            title = scraper.title()
            author = scraper.author()
            time = scraper.total_time()
            yields = scraper.yields()
            ingredients = scraper.ingredients()
            instructions = scraper.instructions_list()
            image = scraper.image()

            scrapedRecipe = Recipe(recipe, title, author, time, yields, 
                ingredients, instructions, image)
            recipes.append(scrapedRecipe)
        except:
            continue
    return recipes

def getUrls(searchTerm):
    urls = [f'https://www.allrecipes.com/search?q={searchTerm}',
    f'https://www.mybakingaddiction.com/?s={searchTerm}',
    f'https://sallysbakingaddiction.com/?s={searchTerm}',
    f'https://tastesbetterfromscratch.com/?s={searchTerm}',
    f'https://www.food.com/search/{searchTerm}',
    f'https://www.bonappetit.com/search?q={searchTerm}']

    return urls