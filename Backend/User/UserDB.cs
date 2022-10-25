using Microsoft.EntityFrameworkCore;

public class UserDB : DbContext
{
    public UserDB(DbContextOptions<UserDB> options) : base(options) { }
    public DbSet<User> Users => Set<User>();

    public UserDB()
    {

    }
}