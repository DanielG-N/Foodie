using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

public class UserRecipes
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }
    public string Username {get; set;} = null!;
    public List<string> SavedRecipes { get; set; } = null!;

    public Recipe(){}
}