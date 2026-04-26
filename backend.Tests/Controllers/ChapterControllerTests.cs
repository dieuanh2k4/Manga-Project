using backend.src.Controllers;
using backend.src.Dtos.Chapter;
using backend.src.Dtos.Exceptions;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using backend.Tests.TestHelpers;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace backend.Tests.Controllers;

public class ChapterControllerTests
{
    [Fact]
    public async Task GetAllChapter_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var chapterService = new Mock<IChapterService>();

        chapterService
            .Setup(x => x.GetAllChapter(1))
            .ReturnsAsync(new List<Chapters>
            {
                new() { Id = 1, MangaId = 1, ChapterNumber = "1", Title = "Chapter 1" }
            });

        var controller = new ChapterController(dbContext, chapterService.Object, ControllerTestHelper.CreateLogger<ChapterController>());

        var result = await controller.GetAllChapter(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<List<Chapters>>(okResult.Value);
        Assert.Single(payload);
    }

    [Fact]
    public async Task GetAllChapter_ReturnsNotFound_WhenServiceThrowsKeyNotFound()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var chapterService = new Mock<IChapterService>();

        chapterService
            .Setup(x => x.GetAllChapter(1))
            .ThrowsAsync(new KeyNotFoundException("Chapter not found"));

        var controller = new ChapterController(dbContext, chapterService.Object, ControllerTestHelper.CreateLogger<ChapterController>());

        var result = await controller.GetAllChapter(1);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(404, objectResult.StatusCode);
        Assert.Equal("Chapter not found", payload.Message);
    }

    [Fact]
    public async Task CreateChapter_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var chapterService = new Mock<IChapterService>();

        chapterService
            .Setup(x => x.CreateChapter(It.IsAny<CreateChapterDto>(), 1))
            .ReturnsAsync(new Chapters { Id = 1, MangaId = 1, ChapterNumber = "1", Title = "Chapter 1" });

        var controller = new ChapterController(dbContext, chapterService.Object, ControllerTestHelper.CreateLogger<ChapterController>());
        var dto = new CreateChapterDto { MangaId = 1, ChapterNumber = "1", Title = "Chapter 1" };

        var result = await controller.CreateChapter(dto, 1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Chapters>(okResult.Value, "data");

        Assert.Equal("Thêm Chapter thành công", message);
        Assert.Equal(1, data?.Id);
    }

    [Fact]
    public async Task CreateChapter_ReturnsBadRequest_WhenServiceThrowsResult()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var chapterService = new Mock<IChapterService>();

        chapterService
            .Setup(x => x.CreateChapter(It.IsAny<CreateChapterDto>(), 1))
            .ThrowsAsync(new Result("Create chapter failed"));

        var controller = new ChapterController(dbContext, chapterService.Object, ControllerTestHelper.CreateLogger<ChapterController>());

        var result = await controller.CreateChapter(new CreateChapterDto { MangaId = 1 }, 1);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(400, objectResult.StatusCode);
        Assert.Equal("Create chapter failed", payload.Message);
    }

    [Fact]
    public async Task UpdateChapter_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var chapterService = new Mock<IChapterService>();

        chapterService
            .Setup(x => x.UpdateChapter(It.IsAny<UpdateChapterDto>(), 1))
            .ReturnsAsync(new Chapters { Id = 1, MangaId = 1, ChapterNumber = "2", Title = "Updated" });

        var controller = new ChapterController(dbContext, chapterService.Object, ControllerTestHelper.CreateLogger<ChapterController>());

        var result = await controller.UpdateChapter(new UpdateChapterDto { MangaId = 1, Title = "Updated" }, 1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Chapters>(okResult.Value, "data");

        Assert.Equal("Cập nhật Chapter thành công", message);
        Assert.Equal("Updated", data?.Title);
    }

    [Fact]
    public async Task UpdateChapter_ReturnsInternalServerError_WhenServiceThrowsUnexpected()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var chapterService = new Mock<IChapterService>();

        chapterService
            .Setup(x => x.UpdateChapter(It.IsAny<UpdateChapterDto>(), 1))
            .ThrowsAsync(new Exception("Boom"));

        var controller = new ChapterController(dbContext, chapterService.Object, ControllerTestHelper.CreateLogger<ChapterController>());

        var result = await controller.UpdateChapter(new UpdateChapterDto { MangaId = 1 }, 1);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(500, objectResult.StatusCode);
        Assert.Equal("An unexpected error occurred.", payload.Message);
    }

    [Fact]
    public async Task DeleteChapter_ReturnsOk_AndRemovesChapterFromContext()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var chapterService = new Mock<IChapterService>();

        var chapter = new Chapters { Id = 1, MangaId = 1, ChapterNumber = "1", Title = "Chapter 1" };
        dbContext.Chapters.Add(chapter);
        await dbContext.SaveChangesAsync();

        chapterService
            .Setup(x => x.DeleteChapter(1, 1))
            .ReturnsAsync(chapter);

        var controller = new ChapterController(dbContext, chapterService.Object, ControllerTestHelper.CreateLogger<ChapterController>());

        var result = await controller.DeleteChapter(1, 1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Chapters>(okResult.Value, "data");

        Assert.Equal("Xóa chapter thành công", message);
        Assert.Equal(1, data?.Id);
        Assert.Empty(dbContext.Chapters);
    }

    [Fact]
    public async Task DeleteChapter_ReturnsBadRequest_WhenServiceThrowsResult()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var chapterService = new Mock<IChapterService>();

        chapterService
            .Setup(x => x.DeleteChapter(1, 1))
            .ThrowsAsync(new Result("Delete chapter failed"));

        var controller = new ChapterController(dbContext, chapterService.Object, ControllerTestHelper.CreateLogger<ChapterController>());

        var result = await controller.DeleteChapter(1, 1);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(400, objectResult.StatusCode);
        Assert.Equal("Delete chapter failed", payload.Message);
    }
}
