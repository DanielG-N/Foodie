using Microsoft.AspNetCore.Mvc;
using MongoDB.Driver;
using MongoDB.Driver.Linq; 

[ApiController]
[Route("recipe")]
public class RecipeController : ControllerBase
{
    private readonly IMongoCollection<Recipe> _recipeDB;

    public RecipeController(RecipeDB recipeDB) =>
        _recipeDB = recipeDB._recipeCollection;

}