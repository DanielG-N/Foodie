using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;

namespace Controllers
{
    [ApiController]
    [Route("user")]
    public class UserController : ControllerBase
    {
        private readonly UserDB _db;
        private readonly IConfiguration _iconfiguration;

        public UserController(ILogger<UserController> logger, UserDB db, IConfiguration iconfiguration)
        {
            _db = db;
            _iconfiguration = iconfiguration;
        }

        [HttpPost]
        [Route("addUser")]
        public async Task<IResult> AddUser(User user)
        {
            _db.Users.Add(user);
            await _db.SaveChangesAsync();
            Tokens token = GenerateToken(user.Id, user.username);
            return Results.Created($"/{user.Id}", token);
        }

        [HttpPost("login")]
        public async Task<ActionResult<Tokens>> Login(User login)
        {
            var user = await _db.Users.Where(u => u.username == login.username && u.password == login.password).SingleOrDefaultAsync();

            if(user != null){
                return (GenerateToken(user.Id, user.username));
            }

            return Unauthorized();
        }

        [HttpGet]
        [Route("{id}")]
        public async Task<ActionResult<User>> GetUser(int id)
        {
            var user = await _db.Users.FindAsync(id);

            if(user == null)
                return NotFound();
            
            return Ok(user);
        }

        [HttpGet]
        [Route("getAllUsers")]
        public async Task<ActionResult<List<User>>> GetAllUsers()
        {
            return await _db.Users.ToListAsync();
        }

        [Authorize]
        [HttpDelete]
        [Route("{id}")]
        public async Task<IResult> DeleteUser(int id)
        {
            if(await _db.Users.FindAsync(id) is User user)
            {
                _db.Users.Remove(user);
                await _db.SaveChangesAsync();
                return Results.Ok(user);
            }

            return Results.NotFound();
        }

        [Authorize]
        [HttpPut]
        [Route("updateUser/{id}")]
        public async Task<IResult> updateUser(User user1)
        {
            var user2 = await _db.Users.FindAsync(user1.Id);

            if(user2 == null)
                return Results.NotFound();
            
            user2.name = user1.name;
            user2.username = user1.username;
            user2.password = user1.password;

            await _db.SaveChangesAsync();

            return Results.NoContent();

        }

        public Tokens GenerateToken(int id, string username){
            // Else we generate JSON Web Token
            var tokenHandler = new JwtSecurityTokenHandler();
            var tokenKey = Encoding.UTF8.GetBytes(_iconfiguration["JWT:Key"]);
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new Claim[]
                {
                    new Claim(ClaimTypes.NameIdentifier, id.ToString()),
                    new Claim(ClaimTypes.Name, username)                    
                }),
                Expires = DateTime.UtcNow.AddHours(12),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(tokenKey),SecurityAlgorithms.HmacSha256Signature)
            };
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return new Tokens { Token = tokenHandler.WriteToken(token), Id = id, Username = username};
    } 
    }
}
