using Microsoft.AspNetCore.Mvc;
using MongoDB.Driver;
using MongoDB.Driver.Linq;
using Steeltoe.Common.Discovery;
using Steeltoe.Discovery;

[ApiController]
[Route("recipe")]
public class RecipeController : ControllerBase
{
    private readonly IMongoCollection<Recipe> _recipeDB;
    DiscoveryHttpClientHandler _handler;

    public RecipeController(RecipeDB recipeDB, IDiscoveryClient client)
    {
        _recipeDB = recipeDB._recipeCollection;
        _handler = new DiscoveryHttpClientHandler(client);
    }

    [HttpPost]
    public async Task<IResult> AddRecipe(Recipe recipe)
    {
        await _recipeDB.InsertOneAsync(recipe);
        return Results.Created($"/{recipe.Id}", recipe);
    }

    [HttpGet("savedRecipes")]
    public async Task<ActionResult<List<Recipe>>> GetRecipesFromList(List<string> ids)
    {
        return await _recipeDB.Find(Builders<Recipe>.Filter.In(r => r.Id, ids)).ToListAsync();
    }

    [HttpGet("random")]
    public async Task<ActionResult<List<Recipe>>> GetRandomRecipes()
    {
        return await _recipeDB.AsQueryable().Sample(10).ToListAsync();
    }

    [HttpPut]
    public async Task<IResult> UpdateRecipe(Recipe recipe)
    {
        await _recipeDB.FindOneAndReplaceAsync(r => r.Id == recipe.Id, recipe);
        return Results.Created($"/{recipe.Id}", recipe);
    }

    [HttpDelete("{id}")]
    public async Task<IResult> DeleteRecipe(string id)
    {
        var recipe = await _recipeDB.FindOneAndDeleteAsync(r => r.Id == id);

        return Results.Ok(recipe);
    }

    [HttpGet("{searchTerm}")]
    public async Task<ActionResult<Recipe>> GetRecipes(string searchTerm)
    {
        //var client = new HttpClient(_handler, false);
        var client = new HttpClient();
        var recipes = await client.GetAsync($"http://scraper:5000/chicken");
        //return response;

        if(recipes == null)
            return NotFound();

        return Ok(recipes);
    }
}