from recipe_scrapers import scrape_me

# give the url as a string, it can be url from any site listed below
scraper = scrape_me('https://www.allrecipes.com/recipe/158968/spinach-and-feta-turkey-burgers/')

# Q: What if the recipe site I want to extract information from is not listed below?
# A: You can give it a try with the wild_mode option! If there is Schema/Recipe available it will work just fine.
# scraper = scrape_me('https://www.feastingathome.com/tomato-risotto/', wild_mode=True)

print(scraper.title())
scraper.total_time()
scraper.yields()
print(scraper.ingredients())
# print(scraper.instructions())  # or alternatively for results as a Python list: scraper.instructions_list()
print(scraper.image())
scraper.host()
scraper.links()
scraper.nutrients()  # if available