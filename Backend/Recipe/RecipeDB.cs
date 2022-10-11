using Microsoft.Extensions.Options;
using MongoDB.Driver;
using MongoDB.Driver.Linq;

public class RecipeDB
{
    public IMongoCollection<Recipe> _recipeCollection;
    public RecipeDB(){}

    public RecipeDB(
        IOptions<RecipeDatabaseSettings> recipeDatabaseSettings)
    {
        var mongoClient = new MongoClient(
            recipeDatabaseSettings.Value.ConnectionString);

        var mongoDatabase = mongoClient.GetDatabase(
            recipeDatabaseSettings.Value.DatabaseName);

        _recipeCollection = mongoDatabase.GetCollection<Recipe>(
            recipeDatabaseSettings.Value.RecipeCollectionName);
    }
}