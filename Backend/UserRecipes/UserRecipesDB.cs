using Microsoft.Extensions.Options;
using MongoDB.Driver;
using MongoDB.Driver.Linq;

public class UserRecipesDB
{
    public IMongoCollection<UserRecipes> _userRecipesCollection;

    public UserRecipesDB(
        IOptions<UserRecipesDatabaseSettings> recipeDatabaseSettings)
    {
        var mongoClient = new MongoClient(
            recipeDatabaseSettings.Value.ConnectionString);

        var mongoDatabase = mongoClient.GetDatabase(
            recipeDatabaseSettings.Value.DatabaseName);

        _userRecipesCollection = mongoDatabase.GetCollection<UserRecipes>(
            recipeDatabaseSettings.Value.RecipeCollectionName);
    }
}