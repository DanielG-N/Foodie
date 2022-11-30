using Microsoft.AspNetCore.Mvc;
using MongoDB.Driver;
using MongoDB.Driver.Linq;
using Steeltoe.Common.Discovery;
using Steeltoe.Discovery;

[ApiController]
[Route("userrecipes")]
public class UserRecipesController : ControllerBase
{
    private readonly IMongoCollection<UserRecipes> _userRecipesDB;
    DiscoveryHttpClientHandler _handler;

    public UserRecipesController(UserRecipesDB userRecipesDB, IDiscoveryClient client)
    {
        _userRecipesDB = userRecipesDB._userRecipesCollection;
        _handler = new DiscoveryHttpClientHandler(client);
    }

    [HttpPut("{username}")]
    public async Task<IResult> SaveRecipe([FromBody] string url, [FromRoute]string username)
    {
        var update = Builders<UserRecipes>.Update
            .Push(u => u.SavedRecipes, url);

        await _userRecipesDB.UpdateOneAsync(u => u.Username == username, update, new UpdateOptions{IsUpsert = true}, default);
        return Results.NoContent();
    }

    [HttpPut("my/{username}")]
    public async Task<IResult> SaveMyRecipe([FromBody] string url, [FromRoute]string username)
    {
        var update = Builders<UserRecipes>.Update
            .Push(u => u.MyRecipes, url);

        await _userRecipesDB.UpdateOneAsync(u => u.Username == username, update, new UpdateOptions{IsUpsert = true}, default);
        return Results.NoContent();
    }

    [HttpGet("{username}")]
    public async Task<ActionResult<List<string>>> GetSavedRecipes(string username){
        UserRecipes savedRecipes = await _userRecipesDB.Find(ur => ur.Username == username).FirstOrDefaultAsync();
        return savedRecipes.SavedRecipes;
    }

    [HttpGet("my/{username}")]
    public async Task<ActionResult<List<string>>> GetMyRecipes(string username){
        UserRecipes savedRecipes = await _userRecipesDB.Find(ur => ur.Username == username).FirstOrDefaultAsync();
        return savedRecipes.MyRecipes;
    }
}