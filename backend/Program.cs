using System.Text.Json.Serialization;
using System.Text;
using backend.src.Configurations;
using backend.src.Data;
using backend.src.Services.Implement;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Extensions.Options;
using Minio;
using Scalar.AspNetCore;
using Server.src.Services.Implements;

DotEnvLoader.Load(Path.Combine(Directory.GetCurrentDirectory(), ".env"));

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();


builder.Services.AddControllers();
builder.Services.AddControllers().AddJsonOptions(option =>
{
   option.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.Preserve;
});

builder.Services.AddHttpContextAccessor();

var jwtSettings = builder.Configuration.GetSection("Jwt");
var jwtKey = jwtSettings["Key"];
if (string.IsNullOrWhiteSpace(jwtKey))
{
    throw new InvalidOperationException("Jwt:Key is missing. Set Jwt__Key in .env or Jwt:Key in configuration.");
}

builder.Services.AddSingleton<JwtHelper>();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings["Issuer"],
            ValidAudience = jwtSettings["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("ReaderOnly", policy => policy.RequireRole("Reader", "Admin"));
});

builder.Services.Configure<MinioOptions>(builder.Configuration.GetSection(MinioOptions.SectionName));

builder.Services.AddSingleton<IMinioClient>(sp =>
{
    var options = sp.GetRequiredService<IOptions<MinioOptions>>().Value;

    return new MinioClient()
        .WithEndpoint(options.Endpoint)
        .WithCredentials(options.AccessKey, options.SecretKey)
        .WithSSL(options.UseSSL)
        .Build();
});

// Database Context
builder.Services.AddDbContext<ApplicationDbContext>(options =>
{
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"),
        npgsqlOptions => npgsqlOptions.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery));
});

// Manga Service
builder.Services.AddScoped<IMangaService, MangaService>();

// Author Service
builder.Services.AddScoped<IAuthorService, AuthorService>();

// Genre Service
builder.Services.AddScoped<IGenreService, GenreService>();

//Admin Service
builder.Services.AddScoped<IAdminService, AdminService>();

// Minio Storage Service
builder.Services.AddScoped<IMinioStorageService, MinioStorageService>();

// Auth Service
builder.Services.AddScoped<IAuthService, AuthService>();

// Chapter Service
builder.Services.AddScoped<IChapterService, ChapterService>();

var app = builder.Build();

// Tự động chạy migrations khi ứng dụng khởi động
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ApplicationDbContext>();
        context.Database.Migrate();
        await SeedData.InitializeAsync(context);
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "Lỗi khi chạy migrations");
    }
}

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.MapGet("/", () =>
{
    if (app.Environment.IsDevelopment())
    {
        return Results.Redirect("/scalar/v1");
    }

    return Results.Ok(new { message = "ProjectManga API is running." });
});

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

// Tự động mở Scalar API Reference khi chạy ứng dụng trong Development
if (app.Environment.IsDevelopment())
{
    var logger = app.Services.GetRequiredService<ILogger<Program>>();

    app.Lifetime.ApplicationStarted.Register(() =>
    {
        try
        {
            var baseUrl = app.Urls.FirstOrDefault() ?? "http://localhost:5219";
            var scalarUrl = $"{baseUrl.TrimEnd('/')}/scalar/v1";

            System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
            {
                FileName = scalarUrl,
                UseShellExecute = true
            });
        }
        catch (Exception ex)
        {
            logger.LogWarning($"Không thể tự động mở browser: {ex.Message}");
        }
    });
}

app.Run();
