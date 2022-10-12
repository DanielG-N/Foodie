using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

public class Recipe
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }
    public List<string> Tags { get; set; } = null!;
    public string Url {get; set;} = null!;
    public string Title { get; set; } = null!;
    public string Author { get; set; } = null!;
    public int Time { get; set; }
    public string Yeild { get; set; } = null!;
    public List<string> Ingredients { get; set; } = null!;
    public List<string> Instructions { get; set; } = null!;
    public string Image { get; set; } = null!;

    public Recipe(){}
}