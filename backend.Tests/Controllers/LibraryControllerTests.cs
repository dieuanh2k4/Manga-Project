using System.Security.Claims;
using backend.src.Controllers;
using backend.src.Dtos.Exceptions;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using backend.Tests.TestHelpers;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace backend.Tests.Controllers;

public class LibraryControllerTests
{
    [Fact]
    public async Task GetMangaInLibrary_ReturnsOk_WhenUserAuthenticated()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var libraryService = new Mock<ILibraryService>();

        libraryService
            .Setup(x => x.GetMangaInLibrary(1))
            .ReturnsAsync(new List<Libraries>
            {
                new() { Id = 1, ReaderId = 1, MangaId = 100 }
            });

        var controller = new LibraryController(dbContext, libraryService.Object, ControllerTestHelper.CreateLogger<LibraryController>());
        SetUserId(controller, 1);

        var result = await controller.GetMangaInLibrary();

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<List<Libraries>>(okResult.Value, "data");

        Assert.Equal("Lấy manga thành công", message);
        Assert.Single(data!);
    }

    [Fact]
    public async Task GetMangaInLibrary_ReturnsUnauthorized_WhenUserMissingClaim()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var libraryService = new Mock<ILibraryService>();
        var controller = new LibraryController(dbContext, libraryService.Object, ControllerTestHelper.CreateLogger<LibraryController>());
        controller.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };

        var result = await controller.GetMangaInLibrary();

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(401, objectResult.StatusCode);
        Assert.Equal("Cần đăng nhập để thêm manga vào thư viện", payload.Message);
    }

    [Fact]
    public async Task AddMangaToLibrary_ReturnsOk_WhenAuthenticated()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var libraryService = new Mock<ILibraryService>();

        libraryService
            .Setup(x => x.AddMangaToLibrary(100, 1))
            .ReturnsAsync(new Libraries { Id = 1, ReaderId = 1, MangaId = 100 });

        var controller = new LibraryController(dbContext, libraryService.Object, ControllerTestHelper.CreateLogger<LibraryController>());
        SetUserId(controller, 1);

        var result = await controller.AddMangaToLibrary(100);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Libraries>(okResult.Value, "data");

        Assert.Equal("Thêm manga thành công vào thư viện", message);
        Assert.Equal(100, data?.MangaId);
    }

    [Fact]
    public async Task AddMangaToLibrary_ReturnsUnauthorized_WhenUserMissingClaim()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var libraryService = new Mock<ILibraryService>();
        var controller = new LibraryController(dbContext, libraryService.Object, ControllerTestHelper.CreateLogger<LibraryController>());
        controller.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };

        var result = await controller.AddMangaToLibrary(100);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(401, objectResult.StatusCode);
        Assert.Equal("Cần đăng nhập để thêm manga vào thư viện", payload.Message);
    }

    [Fact]
    public async Task DeleteMangaToLibrary_ReturnsOk_WhenAuthenticated()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var libraryService = new Mock<ILibraryService>();

        libraryService
            .Setup(x => x.DeleteMangaToLibrary(100, 1))
            .ReturnsAsync(new Libraries { Id = 1, ReaderId = 1, MangaId = 100 });

        var controller = new LibraryController(dbContext, libraryService.Object, ControllerTestHelper.CreateLogger<LibraryController>());
        SetUserId(controller, 1);

        var result = await controller.DeleteMangaToLibrary(100);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Libraries>(okResult.Value, "data");

        Assert.Equal("Xóa manga thành công", message);
        Assert.Equal(100, data?.MangaId);
    }

    [Fact]
    public async Task DeleteMangaToLibrary_ReturnsBadRequest_WhenServiceThrowsResult()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var libraryService = new Mock<ILibraryService>();

        libraryService
            .Setup(x => x.DeleteMangaToLibrary(100, 1))
            .ThrowsAsync(new Result("Delete failed"));

        var controller = new LibraryController(dbContext, libraryService.Object, ControllerTestHelper.CreateLogger<LibraryController>());
        SetUserId(controller, 1);

        var result = await controller.DeleteMangaToLibrary(100);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(400, objectResult.StatusCode);
        Assert.Equal("Delete failed", payload.Message);
    }

    private static void SetUserId(LibraryController controller, int userId)
    {
        controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(new ClaimsIdentity(
                    new[] { new Claim(ClaimTypes.NameIdentifier, userId.ToString()) },
                    "TestAuth"))
            }
        };
    }
}
