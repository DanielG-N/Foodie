using Microsoft.Extensions.Options;
using MongoDB.Driver;
using MongoDB.Driver.Linq;

public class UserRecipesDB
{
    public IMongoCollection<UserRecipes> _userRecipesCollection;
    public RecipeDB(){}

    public RecipeDB(
        IOptions<UserRecipesDatabaseSettings> recipeDatabaseSettings)
    {
        var mongoClient = new MongoClient(
            recipeDatabaseSettings.Value.ConnectionString);

        var mongoDatabase = mongoClient.GetDatabase(
            recipeDatabaseSettings.Value.DatabaseName);

        _recipeCollection = mongoDatabase.GetCollection<Recipe>(
            recipeDatabaseSettings.Value.RecipeCollectionName);
    }
}