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