using backend.src.Controllers;
using backend.src.Dtos.Exceptions;
using backend.src.Dtos.Genre;
using backend.src.Models;
using backend.src.Services.Interface;
using backend.Tests.TestHelpers;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace backend.Tests.Controllers;

public class GenreControllerTests
{
    [Fact]
    public async Task GetAllGenre_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var genreService = new Mock<IGenreService>();

        genreService
            .Setup(x => x.GetAllGenre())
            .ReturnsAsync(new List<Genres> { new() { Id = 1, Name = "Action" } });

        var controller = new GenreController(dbContext, genreService.Object, ControllerTestHelper.CreateLogger<GenreController>());

        var result = await controller.GetAllGenre();

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<List<Genres>>(okResult.Value);
        Assert.Single(payload);
    }

    [Fact]
    public async Task CreateGenre_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var genreService = new Mock<IGenreService>();

        genreService
            .Setup(x => x.CreateGenre(It.IsAny<CreateGenreDto>()))
            .ReturnsAsync(new Genres { Id = 1, Name = "Action" });

        var controller = new GenreController(dbContext, genreService.Object, ControllerTestHelper.CreateLogger<GenreController>());

        var result = await controller.CreateGenre(new CreateGenreDto { Name = "Action" });

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<Genres>(okResult.Value);
        Assert.Equal("Action", payload.Name);
    }

    [Fact]
    public async Task UpdateGenre_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var genreService = new Mock<IGenreService>();

        genreService
            .Setup(x => x.UpdateGenre(It.IsAny<UpdateGenreDto>(), 1))
            .ReturnsAsync(new Genres { Id = 1, Name = "Romance" });

        var controller = new GenreController(dbContext, genreService.Object, ControllerTestHelper.CreateLogger<GenreController>());

        var result = await controller.UpdateGenre(new UpdateGenreDto { Name = "Romance" }, 1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<Genres>(okResult.Value);
        Assert.Equal("Romance", payload.Name);
    }

    [Fact]
    public async Task DeleteGenre_ReturnsBadRequestResultMessage_WhenDeleteSucceeds()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var genreService = new Mock<IGenreService>();
        var genre = new Genres { Id = 1, Name = "Action" };

        dbContext.Genres.Add(genre);
        await dbContext.SaveChangesAsync();

        genreService
            .Setup(x => x.DeleteGenre(1))
            .ReturnsAsync(genre);

        var controller = new GenreController(dbContext, genreService.Object, ControllerTestHelper.CreateLogger<GenreController>());

        var result = await controller.DeleteGenre(1);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(400, objectResult.StatusCode);
        Assert.Equal("Xóa thể loại thành công", payload.Message);
    }
}
