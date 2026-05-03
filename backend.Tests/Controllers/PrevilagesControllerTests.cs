using backend.src.Controllers;
using backend.src.Dtos.Exceptions;
using backend.src.Dtos.Previlage;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using backend.Tests.TestHelpers;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace backend.Tests.Controllers;

public class PrevilagesControllerTests
{
    [Fact]
    public async Task GetAllPrevilage_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var previlageService = new Mock<IPrevilageService>();

        dbContext.Previlages.Add(new Previlages { Id = 1, Content = "Read premium" });
        await dbContext.SaveChangesAsync();

        var controller = new PrevilagesController(dbContext, previlageService.Object, ControllerTestHelper.CreateLogger<PrevilagesController>());

        var result = await controller.GetAllPrevilage();

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<List<Previlages>>(okResult.Value, "data");

        Assert.Equal("Lấy đặc quyền thành công", message);
        Assert.Single(data!);
    }

    [Fact]
    public async Task GetAllPrevilage_ReturnsInternalServerError_WhenDbContextDisposed()
    {
        var dbContext = ControllerTestHelper.CreateDbContext();
        var previlageService = new Mock<IPrevilageService>();
        var controller = new PrevilagesController(dbContext, previlageService.Object, ControllerTestHelper.CreateLogger<PrevilagesController>());

        await dbContext.DisposeAsync();

        var result = await controller.GetAllPrevilage();

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(500, objectResult.StatusCode);
        Assert.Equal("An unexpected error occurred.", payload.Message);
    }

    [Fact]
    public async Task CreatePrevilage_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var previlageService = new Mock<IPrevilageService>();

        previlageService
            .Setup(x => x.CreatePrevilage(It.IsAny<CreatePrevilageDto>()))
            .ReturnsAsync(new Previlages { Id = 1, Content = "Read premium" });

        var controller = new PrevilagesController(dbContext, previlageService.Object, ControllerTestHelper.CreateLogger<PrevilagesController>());

        var result = await controller.CreatePrevilage(new CreatePrevilageDto { Content = "Read premium" });

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Previlages>(okResult.Value, "data");

        Assert.Equal("Lấy đặc quyền thành công", message);
        Assert.Equal(1, data?.Id);
    }

    [Fact]
    public async Task CreatePrevilage_ReturnsBadRequest_WhenServiceThrowsResult()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var previlageService = new Mock<IPrevilageService>();

        previlageService
            .Setup(x => x.CreatePrevilage(It.IsAny<CreatePrevilageDto>()))
            .ThrowsAsync(new Result("Create previlage failed"));

        var controller = new PrevilagesController(dbContext, previlageService.Object, ControllerTestHelper.CreateLogger<PrevilagesController>());

        var result = await controller.CreatePrevilage(new CreatePrevilageDto());

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(400, objectResult.StatusCode);
        Assert.Equal("Create previlage failed", payload.Message);
    }

    [Fact]
    public async Task UpdatePrevilage_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var previlageService = new Mock<IPrevilageService>();

        previlageService
            .Setup(x => x.UpdatePrevilage(It.IsAny<UpdatePrevilageDto>(), 1))
            .ReturnsAsync(new Previlages { Id = 1, Content = "Updated" });

        var controller = new PrevilagesController(dbContext, previlageService.Object, ControllerTestHelper.CreateLogger<PrevilagesController>());

        var result = await controller.UpdatePrevilage(new UpdatePrevilageDto { Content = "Updated" }, 1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Previlages>(okResult.Value, "data");

        Assert.Equal("Cập nhật đặc quyền thành công", message);
        Assert.Equal("Updated", data?.Content);
    }

    [Fact]
    public async Task DeletePrevilage_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var previlageService = new Mock<IPrevilageService>();

        previlageService
            .Setup(x => x.DeletePrevilage(1))
            .ReturnsAsync(new Previlages { Id = 1, Content = "Removed" });

        var controller = new PrevilagesController(dbContext, previlageService.Object, ControllerTestHelper.CreateLogger<PrevilagesController>());

        var result = await controller.DeletePrevilage(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Previlages>(okResult.Value, "data");

        Assert.Equal("Xóa đặc quyền thành công", message);
        Assert.Equal(1, data?.Id);
    }

    [Fact]
    public async Task DeletePrevilage_ReturnsNotFound_WhenServiceThrowsKeyNotFound()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var previlageService = new Mock<IPrevilageService>();

        previlageService
            .Setup(x => x.DeletePrevilage(1))
            .ThrowsAsync(new KeyNotFoundException("Previlage not found"));

        var controller = new PrevilagesController(dbContext, previlageService.Object, ControllerTestHelper.CreateLogger<PrevilagesController>());

        var result = await controller.DeletePrevilage(1);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(404, objectResult.StatusCode);
        Assert.Equal("Previlage not found", payload.Message);
    }
}
