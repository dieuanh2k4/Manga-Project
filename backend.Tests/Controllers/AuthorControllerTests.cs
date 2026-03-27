using backend.src.Controllers;
using backend.src.Dtos.Author;
using backend.src.Dtos.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using backend.Tests.TestHelpers;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace backend.Tests.Controllers;

public class AuthorControllerTests
{
    [Fact]
    public async Task GetAllAuthor_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var authorService = new Mock<IAuthorService>();

        authorService
            .Setup(x => x.GetAllAuthor())
            .ReturnsAsync(new List<Authors> { new() { Id = 1, FullName = "A" } });

        var controller = new AuthorController(dbContext, authorService.Object, ControllerTestHelper.CreateLogger<AuthorController>());

        var result = await controller.GetAllAuthor();

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<List<Authors>>(okResult.Value);
        Assert.Single(payload);
    }

    [Fact]
    public async Task GetAuthorById_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var authorService = new Mock<IAuthorService>();

        authorService
            .Setup(x => x.GetAllAuthorById(1))
            .ReturnsAsync(new Authors { Id = 1, FullName = "A" });

        var controller = new AuthorController(dbContext, authorService.Object, ControllerTestHelper.CreateLogger<AuthorController>());

        var result = await controller.GetAuthorById(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<Authors>(okResult.Value);
        Assert.Equal(1, payload.Id);
    }

    [Fact]
    public async Task CreateAuthor_ReturnsOk_AndUploadsImage_WhenFileProvided()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var authorService = new Mock<IAuthorService>();
        var file = ControllerTestHelper.CreateFormFile();

        authorService
            .Setup(x => x.UploadImage(It.IsAny<IFormFile>()))
            .ReturnsAsync("https://cdn/avatar.png");

        authorService
            .Setup(x => x.CreateAuthor(It.IsAny<CreateAuthorDto>()))
            .ReturnsAsync(new Authors { Id = 1, FullName = "New" });

        var controller = new AuthorController(dbContext, authorService.Object, ControllerTestHelper.CreateLogger<AuthorController>());
        var dto = new CreateAuthorDto { FullName = "New" };

        var result = await controller.CreateAuthor(dto, file);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<Authors>(okResult.Value);
        Assert.Equal(1, payload.Id);
        authorService.Verify(x => x.UploadImage(It.IsAny<IFormFile>()), Times.Once);
    }

    [Fact]
    public async Task UpdateAuthor_ReturnsOk_AndUploadsImage_WhenFileProvided()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var authorService = new Mock<IAuthorService>();
        var file = ControllerTestHelper.CreateFormFile();

        authorService
            .Setup(x => x.UploadImage(It.IsAny<IFormFile>()))
            .ReturnsAsync("https://cdn/avatar.png");

        authorService
            .Setup(x => x.UpdateAuthor(It.IsAny<UpdateAuthorDto>(), 1))
            .ReturnsAsync(new Authors { Id = 1, FullName = "Updated" });

        var controller = new AuthorController(dbContext, authorService.Object, ControllerTestHelper.CreateLogger<AuthorController>());

        var result = await controller.UpdateAuthor(new UpdateAuthorDto { FullName = "Updated" }, file, 1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<Authors>(okResult.Value);
        Assert.Equal("Updated", payload.FullName);
        authorService.Verify(x => x.UploadImage(It.IsAny<IFormFile>()), Times.Once);
    }

    [Fact]
    public async Task DeleteAuthor_ReturnsBadRequestResultMessage_WhenDeleteSucceeds()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var authorService = new Mock<IAuthorService>();
        var author = new Authors { Id = 1, FullName = "A" };

        dbContext.Authors.Add(author);
        await dbContext.SaveChangesAsync();

        authorService
            .Setup(x => x.DeleteAuthor(1))
            .ReturnsAsync(author);

        var controller = new AuthorController(dbContext, authorService.Object, ControllerTestHelper.CreateLogger<AuthorController>());

        var result = await controller.DeleteAuthor(1);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(400, objectResult.StatusCode);
        Assert.Equal("Xóa tác giả thành công", payload.Message);
    }
}
