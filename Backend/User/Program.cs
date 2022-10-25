using Microsoft.EntityFrameworkCore;
using Steeltoe.Discovery.Client;
using Steeltoe.Common.Discovery;
using Steeltoe.Discovery.Eureka;
using Steeltoe.Discovery;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var  policyName = "_myAllowSpecificOrigins";
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddAuthentication(x =>
	{
		x.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
		x.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
	}).AddJwtBearer(o =>
	{
		var Key = Encoding.UTF8.GetBytes(builder.Configuration["JWT:Key"]);
		o.SaveToken = true;
		o.TokenValidationParameters = new TokenValidationParameters
		{
			ValidateIssuer = false,
			ValidateAudience = false,
			ValidateLifetime = true,
			ValidateIssuerSigningKey = true,
			ValidIssuer = builder.Configuration["JWT:Issuer"],
			ValidAudience = builder.Configuration["JWT:Audience"],
			IssuerSigningKey = new SymmetricSecurityKey(Key)
		};
	});
builder.Services.AddControllers();
builder.Services.AddDiscoveryClient(builder.Configuration);
builder.Services.AddDbContext<UserDB>(opt => opt.UseSqlServer(builder.Configuration.GetConnectionString("userDb1")));
builder.Services.AddCors(options =>
{
    options.AddPolicy(name: policyName,
                    builder =>
                    {
                        builder
                            .WithOrigins("*") // specifying the allowed origin
                            .WithMethods("*") // defining the allowed HTTP method
                            .AllowAnyHeader(); // allowing any header to be sent
                    });
});


var app = builder.Build();
app.UseCors(policyName);
app.UseAuthentication(); 	
app.UseAuthorization();
app.MapControllers();

app.MapGet("/", () => "Hello World!");

app.Run();
