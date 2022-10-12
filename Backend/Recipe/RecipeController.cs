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