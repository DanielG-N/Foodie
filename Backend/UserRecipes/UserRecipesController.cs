using Microsoft.AspNetCore.Mvc;
using MongoDB.Driver;
using MongoDB.Driver.Linq;
using Steeltoe.Common.Discovery;
using Steeltoe.Discovery;

[ApiController]
[Route("recipe")]
public class UserRecipesController : ControllerBase
{
    private readonly IMongoCollection<UserRecipes> _userRecipesDB;
    DiscoveryHttpClientHandler _handler;

    public UserRecipesController(UserRecipesDB userRecipesDB, IDiscoveryClient client)
    {
        _userRecipesDB = userRecipesDB._userRecipesCollection;
        _handler = new DiscoveryHttpClientHandler(client);
    }

    
}