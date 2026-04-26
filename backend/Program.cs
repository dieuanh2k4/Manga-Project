using System.Text.Json.Serialization;
using System.Text;
using backend.src.Configurations;
using backend.src.Data;
using backend.src.Hubs;
using backend.src.Services.Implement;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using System.Security.Claims;
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

builder.Services.AddSignalR(); // gửi thông báo realtime

builder.Services.AddHttpContextAccessor();

builder.Services.AddCors(options =>
{
    options.AddPolicy("WebAdminCors", policy =>
    {
        policy
            // Allow localhost/127.0.0.1 for local web frontend even when the dev port changes.
            .SetIsOriginAllowed(origin =>
            {
                if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri))
                {
                    return false;
                }

                return uri.Host.Equals("localhost", StringComparison.OrdinalIgnoreCase)
                    || uri.Host.Equals("127.0.0.1", StringComparison.OrdinalIgnoreCase);
            })
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

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
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var requestPath = context.HttpContext.Request.Path;

                if (!string.IsNullOrEmpty(accessToken) && requestPath.StartsWithSegments("/hubs/notifications"))
                {
                    context.Token = accessToken;
                }

                return Task.CompletedTask;
            },
            OnTokenValidated = async context =>
            {
                var userIdClaim = context.Principal?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var tokenVersionClaim = context.Principal?.FindFirst("tokenVersion")?.Value;

                if (!int.TryParse(userIdClaim, out var userId))
                {
                    context.Fail("Invalid token claims");
                    return;
                }

                if (!int.TryParse(tokenVersionClaim, out var tokenVersion))
                {
                    context.Fail("Invalid token version");
                    return;
                }

                var dbContext = context.HttpContext.RequestServices.GetRequiredService<ApplicationDbContext>();
                var dbUser = await dbContext.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == userId);
                if (dbUser == null)
                {
                    context.Fail("User does not exist");
                    return;
                }

                if (dbUser.TokenVersion != tokenVersion)
                {
                    context.Fail("Token has been invalidated");
                }
            }
        };

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
    options.ConfigureWarnings(w => w.Ignore(RelationalEventId.PendingModelChangesWarning));
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

// Page Service
builder.Services.AddScoped<IPageService, PageService>();

// Package Service
builder.Services.AddScoped<IPackageService, PackageService>();

// Entitlement Service
builder.Services.AddScoped<IEntitlementService, EntitlementService>();

// Previlage Service
builder.Services.AddScoped<IPrevilageService, PrevilageService>();

// Library Service
builder.Services.AddScoped<ILibraryService, LibraryService>();

// Notification Service
builder.Services.AddScoped<INotificationService, NotificationService>();

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

app.UseCors("WebAdminCors");

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.MapHub<NotificationHub>("/hubs/notifications");

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
