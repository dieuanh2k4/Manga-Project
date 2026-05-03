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

public class PageControllerTests
{
    [Fact]
    public async Task GetAllPage_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var pageService = new Mock<IPageService>();

        pageService
            .Setup(x => x.GetAllPage(1, 2, null))
            .ReturnsAsync(new List<Pages>
            {
                new() { Id = 1, MangaId = 1, ChapterId = 2, ImageUrl = "https://cdn/1.png" }
            });

        var controller = new PageController(dbContext, pageService.Object, ControllerTestHelper.CreateLogger<PageController>());

        var result = await controller.GetAllPage(1, 2);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<List<Pages>>(okResult.Value);
        Assert.Single(payload);
    }

    [Fact]
    public async Task GetAllPage_ReturnsBadRequest_WhenServiceThrowsResult()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var pageService = new Mock<IPageService>();

        pageService
            .Setup(x => x.GetAllPage(1, 2, null))
            .ThrowsAsync(new Result("Không có page"));

        var controller = new PageController(dbContext, pageService.Object, ControllerTestHelper.CreateLogger<PageController>());

        var result = await controller.GetAllPage(1, 2);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(400, objectResult.StatusCode);
        Assert.Equal("Không có page", payload.Message);
    }

    [Fact]
    public async Task AddPageToChapter_ReturnsOk_WhenFilesProvided()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var pageService = new Mock<IPageService>();

        var files = new List<IFormFile>
        {
            ControllerTestHelper.CreateFormFile("1.png"),
            ControllerTestHelper.CreateFormFile("2.png")
        };

        pageService
            .Setup(x => x.AddPageToChapter(1, 2, It.IsAny<List<IFormFile>>()))
            .ReturnsAsync(new List<Pages>
            {
                new() { Id = 1, MangaId = 1, ChapterId = 2, ImageUrl = "https://cdn/1.png" },
                new() { Id = 2, MangaId = 1, ChapterId = 2, ImageUrl = "https://cdn/2.png" }
            });

        var controller = new PageController(dbContext, pageService.Object, ControllerTestHelper.CreateLogger<PageController>());

        var result = await controller.AddPageToChapter(1, 2, files);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<List<Pages>>(okResult.Value, "data");

        Assert.Equal("Thêm page thành công", message);
        Assert.Equal(2, data?.Count);
        pageService.Verify(x => x.AddPageToChapter(1, 2, It.IsAny<List<IFormFile>>()), Times.Once);
    }

    [Fact]
    public async Task AddPageToChapter_ReturnsInternalServerError_WhenServiceThrowsUnexpected()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var pageService = new Mock<IPageService>();

        pageService
            .Setup(x => x.AddPageToChapter(1, 2, It.IsAny<List<IFormFile>>()))
            .ThrowsAsync(new Exception("Boom"));

        var controller = new PageController(dbContext, pageService.Object, ControllerTestHelper.CreateLogger<PageController>());

        var result = await controller.AddPageToChapter(1, 2, new List<IFormFile>());

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(500, objectResult.StatusCode);
        Assert.Equal("An unexpected error occurred.", payload.Message);
    }

    [Fact]
    public async Task DeletePageOfChapter_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var pageService = new Mock<IPageService>();

        pageService
            .Setup(x => x.DeletePageOfChapter(1, 2, It.IsAny<List<int>>()))
            .ReturnsAsync(new List<Pages>
            {
                new() { Id = 1, MangaId = 1, ChapterId = 2, ImageUrl = "https://cdn/1.png" }
            });

        var controller = new PageController(dbContext, pageService.Object, ControllerTestHelper.CreateLogger<PageController>());

        var result = await controller.DeletePageOfChapter(1, 2, new List<int> { 1 });

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<List<Pages>>(okResult.Value, "data");

        Assert.Equal("Xóa page thành công", message);
        Assert.Single(data!);
    }

    [Fact]
    public async Task DeletePageOfChapter_ReturnsBadRequest_WhenServiceThrowsResult()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var pageService = new Mock<IPageService>();

        pageService
            .Setup(x => x.DeletePageOfChapter(1, 2, It.IsAny<List<int>>()))
            .ThrowsAsync(new Result("Delete page failed"));

        var controller = new PageController(dbContext, pageService.Object, ControllerTestHelper.CreateLogger<PageController>());

        var result = await controller.DeletePageOfChapter(1, 2, new List<int> { 1 });

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(400, objectResult.StatusCode);
        Assert.Equal("Delete page failed", payload.Message);
    }
}
