using System.Reflection;
using backend.src.Data;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;

namespace backend.Tests.TestHelpers;

internal static class ControllerTestHelper
{
    public static ApplicationDbContext CreateDbContext()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new ApplicationDbContext(options);
    }

    public static ILogger<T> CreateLogger<T>() where T : class
    {
        return new Mock<ILogger<T>>().Object;
    }

    public static IFormFile CreateFormFile(string fileName = "avatar.png", string contentType = "image/png")
    {
        var bytes = new byte[] { 1, 2, 3, 4 };
        var stream = new MemoryStream(bytes);

        return new FormFile(stream, 0, stream.Length, "file", fileName)
        {
            Headers = new HeaderDictionary(),
            ContentType = contentType
        };
    }

    public static T? GetAnonymousProperty<T>(object source, string propertyName)
    {
        var property = source.GetType().GetProperty(propertyName, BindingFlags.Public | BindingFlags.Instance);
        if (property is null)
        {
            return default;
        }

        return (T?)property.GetValue(source);
    }
}
