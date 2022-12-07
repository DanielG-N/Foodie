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

    [HttpPost("savedRecipes")]
    public async Task<ActionResult<List<Recipe>>> GetRecipesFromList(List<string> urls)
    {
        return await _recipeDB.Find(Builders<Recipe>.Filter.In(r => r.Url, urls)).ToListAsync();
    }

    [HttpGet("search/{searchTerm}")]
    public async Task<ActionResult<List<Recipe>>> SearchRecipes(string searchTerm)
    {
        return await _recipeDB.Find(r => r.Title.ToLower().Contains(searchTerm.ToLower())).ToListAsync();
    }

    [HttpGet("random")]
    public async Task<ActionResult<List<Recipe>>> GetRandomRecipes()
    {
        return await _recipeDB.AsQueryable().Sample(200).ToListAsync();
    }

    [HttpPut]
    public async Task<IResult> UpdateRecipe(Recipe recipe)
    {
        await _recipeDB.FindOneAndReplaceAsync(r => r.Id == recipe.Id, recipe);
        return Results.Created($"/{recipe.Id}", recipe);
    }

    [HttpDelete]
    public async Task<IResult> DeleteRecipe([FromBody] string url)
    {
        var recipe = await _recipeDB.FindOneAndDeleteAsync(r => r.Url == url);

        return Results.Ok(recipe);
    }
}