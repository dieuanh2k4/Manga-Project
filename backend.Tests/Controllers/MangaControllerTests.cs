using backend.src.Controllers;
using backend.src.Dtos.Exceptions;
using backend.src.Dtos.Manga;
using backend.src.Models;
using backend.src.Services.Interface;
using backend.Tests.TestHelpers;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace backend.Tests.Controllers;

public class MangaControllerTests
{
    [Fact]
    public async Task GetAllManga_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var mangaService = new Mock<IMangaService>();

        mangaService
            .Setup(x => x.GetAllManga())
            .ReturnsAsync(new List<Manga>
            {
                new()
                {
                    Id = 1,
                    Title = "Manga",
                    ReleaseDate = new DateOnly(2024, 1, 1),
                    EndDate = new DateOnly(2024, 1, 1)
                }
            });

        var controller = new MangaController(dbContext, mangaService.Object, ControllerTestHelper.CreateLogger<MangaController>());

        var result = await controller.GetAllManga();

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<List<Manga>>(okResult.Value);
        Assert.Single(payload);
    }

    [Fact]
    public async Task GetMangaById_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var mangaService = new Mock<IMangaService>();

        mangaService
            .Setup(x => x.GetAllMangaById(1))
            .ReturnsAsync(new Manga
            {
                Id = 1,
                Title = "Manga",
                ReleaseDate = new DateOnly(2024, 1, 1),
                EndDate = new DateOnly(2024, 1, 1)
            });

        var controller = new MangaController(dbContext, mangaService.Object, ControllerTestHelper.CreateLogger<MangaController>());

        var result = await controller.GetMangaById(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<Manga>(okResult.Value);
        Assert.Equal(1, payload.Id);
    }

    [Fact]
    public async Task CreateManga_ReturnsOk_AndUploadsImage_WhenFileProvided()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var mangaService = new Mock<IMangaService>();
        var file = ControllerTestHelper.CreateFormFile("thumbnail.png");

        mangaService
            .Setup(x => x.UploadImage(It.IsAny<IFormFile>()))
            .ReturnsAsync("https://cdn/thumbnail.png");

        mangaService
            .Setup(x => x.CreateManga(It.IsAny<CreateMangaDto>()))
            .ReturnsAsync(new Manga
            {
                Id = 1,
                Title = "Manga",
                ReleaseDate = new DateOnly(2024, 1, 1),
                EndDate = new DateOnly(2024, 1, 1)
            });

        var controller = new MangaController(dbContext, mangaService.Object, ControllerTestHelper.CreateLogger<MangaController>());
        var dto = new CreateMangaDto { Title = "Manga" };

        var result = await controller.CreateManga(dto, file);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Manga>(okResult.Value, "data");

        Assert.Equal("Thêm Manga thành công", message);
        Assert.Equal(1, data?.Id);
        mangaService.Verify(x => x.UploadImage(It.IsAny<IFormFile>()), Times.Once);
    }

    [Fact]
    public async Task UpdateManga_ReturnsOk_AndUploadsImage_WhenFileProvided()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var mangaService = new Mock<IMangaService>();
        var file = ControllerTestHelper.CreateFormFile("thumbnail.png");

        mangaService
            .Setup(x => x.UploadImage(It.IsAny<IFormFile>()))
            .ReturnsAsync("https://cdn/thumbnail.png");

        mangaService
            .Setup(x => x.UpdateManga(It.IsAny<UpdateMangaDto>(), 1))
            .ReturnsAsync(new Manga
            {
                Id = 1,
                Title = "Updated",
                ReleaseDate = new DateOnly(2024, 1, 1),
                EndDate = new DateOnly(2024, 1, 1)
            });

        var controller = new MangaController(dbContext, mangaService.Object, ControllerTestHelper.CreateLogger<MangaController>());

        var result = await controller.UpdateManga(new UpdateMangaDto { Title = "Updated" }, file, 1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Manga>(okResult.Value, "data");

        Assert.Equal("Cập nhật Manga thành công", message);
        Assert.Equal("Updated", data?.Title);
        mangaService.Verify(x => x.UploadImage(It.IsAny<IFormFile>()), Times.Once);
    }

    [Fact]
    public async Task DeleteManga_ReturnsOkResultMessage_WhenDeleteSucceeds()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var mangaService = new Mock<IMangaService>();
        var manga = new Manga
        {
            Id = 1,
            Title = "Manga",
            Status = "Ongoing",
            ReleaseDate = new DateOnly(2024, 1, 1),
            EndDate = new DateOnly(2024, 1, 1)
        };

        dbContext.Manga.Add(manga);
        await dbContext.SaveChangesAsync();

        mangaService
            .Setup(x => x.DeleteManga(1))
            .ReturnsAsync(manga);

        var controller = new MangaController(dbContext, mangaService.Object, ControllerTestHelper.CreateLogger<MangaController>());

        var result = await controller.DeleteManga(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Manga>(okResult.Value, "data");

        Assert.Equal("Cập nhật manga thành công", message);
        Assert.Equal(1, data?.Id);
    }
}
