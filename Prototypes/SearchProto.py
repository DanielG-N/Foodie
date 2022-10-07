from bs4 import BeautifulSoup
from urllib.request import urlopen, Request
from recipe_scrapers import scrape_me
from datetime import date, timedelta
from multiprocessing.dummy import Pool
import tqdm

searchTerm = "chicken"
urls = [f'https://www.allrecipes.com/search?q={searchTerm}',
f'https://www.mybakingaddiction.com/?s={searchTerm}',
f'https://sallysbakingaddiction.com/?s={searchTerm}',
f'https://tastesbetterfromscratch.com/?s={searchTerm}',
f'https://www.food.com/search/{searchTerm}',
f'https://www.bonappetit.com/search?q={searchTerm}']

class Recipe:
    def __init__(self, url, title, author, time, yeild, ingredients, instructions, image) -> None:
        self.url = url
        self.title = title
        self.author = author
        self.time = time
        self.yeild = yeild
        self.ingredients = ingredients
        self.instructions = instructions
        self.image = image
    
    def __str__(self):
        return f"{self.url}\n{self.title}\n{self.ingredients}\n{self.instructions}\n"

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

            scrapedRecipe = Recipe(recipe, title, author, time, yields, 
                ingredients, instructions, image)
            recipes.append(scrapedRecipe)
        except:
            continue
    return recipes

if __name__ == '__main__':
    # for url in urls:
    #     ScrapeSite(url)
    #     print('done')
    with Pool(processes=8) as pool, tqdm.tqdm(total=len(urls)) as pbar:
        recipes = []
        for data in pool.imap_unordered(ScrapeSite, urls):                 # send urls from all_urls list to parse() function (it will be done concurently in process pool). The results returned will be unordered (returned when they are available, without waiting for other processes)
            recipes.extend(data)                                           # update all_data list
            pbar.update() 
            # print(recipes)

    for recipe in recipes:
        print(recipe)

