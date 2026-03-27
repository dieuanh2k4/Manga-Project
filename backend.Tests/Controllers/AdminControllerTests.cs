using backend.src.Controllers;
using backend.src.Dtos.Admin;
using backend.src.Models;
using backend.src.Services.Interface;
using backend.Tests.TestHelpers;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace backend.Tests.Controllers;

public class AdminControllerTests
{
    [Fact]
    public async Task GetInfoAdmin_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.GetInfoAdmin())
            .ReturnsAsync(new List<Admin> { new() { Id = 1, Name = "Admin" } });

        var controller = new AdminController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var result = await controller.GetInfoAdmin();

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<List<Admin>>(okResult.Value);
        Assert.Single(payload);
    }

    [Fact]
    public async Task GetAdminById_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.GetInfoAdminById(1))
            .ReturnsAsync(new Admin { Id = 1, Name = "Admin" });

        var controller = new AdminController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var result = await controller.GetAdminById(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<Admin>(okResult.Value);
        Assert.Equal(1, payload.Id);
    }

    [Fact]
    public async Task CreateAdmin_ReturnsOk_WhenNoFileProvided()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.CreateAdmin(It.IsAny<CreateAdminDto>()))
            .ReturnsAsync(new Admin { Id = 1, Name = "Admin" });

        var controller = new AdminController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var result = await controller.CreateAdmin(new CreateAdminDto { Name = "Admin" }, null);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var user = ControllerTestHelper.GetAnonymousProperty<Admin>(okResult.Value, "user");

        Assert.Equal("Tạo Admin thành công", message);
        Assert.Equal(1, user?.Id);
    }

    [Fact]
    public async Task UpdateAdmin_ReturnsOk_WhenNoFileProvided()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.UpdateAdmin(It.IsAny<UpdateAdminDto>(), 1))
            .ReturnsAsync(new Admin { Id = 1, Name = "Updated" });

        var controller = new AdminController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var result = await controller.UpdateAdmin(new UpdateAdminDto { Name = "Updated" }, null, 1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var user = ControllerTestHelper.GetAnonymousProperty<Admin>(okResult.Value, "user");

        Assert.Equal("Cập nhật thành công", message);
        Assert.Equal("Updated", user?.Name);
    }

    [Fact]
    public async Task DeleteAdmin_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.DeleteAdmin(1))
            .ReturnsAsync(new Admin { Id = 1, Name = "Deleted" });

        var controller = new AdminController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var result = await controller.DeleteAdmin(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var user = ControllerTestHelper.GetAnonymousProperty<Admin>(okResult.Value, "user");

        Assert.Equal("Xóa Admin thành công", message);
        Assert.Equal(1, user?.Id);
    }

    [Fact]
    public async Task GetInfoReader_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.GetInfoReader())
            .ReturnsAsync(new List<Readers> { new() { Id = 1, FullName = "Reader" } });

        var controller = new AdminController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var result = await controller.GetInfoReader();

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<List<Readers>>(okResult.Value);
        Assert.Single(payload);
    }

    [Fact]
    public async Task GetReaderById_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.GetInfoReaderById(1))
            .ReturnsAsync(new Readers { Id = 1, FullName = "Reader" });

        var controller = new AdminController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var result = await controller.GetReaderById(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<Readers>(okResult.Value);
        Assert.Equal(1, payload.Id);
    }

    [Fact]
    public async Task CreateReader_ReturnsOk_WhenNoFileProvided()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.CreateReader(It.IsAny<CreateReaderDto>(), "reader", "123"))
            .ReturnsAsync(new Readers { Id = 1, FullName = "Reader" });

        var controller = new AdminController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var result = await controller.CreateReader(new CreateReaderDto { FullName = "Reader" }, "reader", "123", null);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var user = ControllerTestHelper.GetAnonymousProperty<Readers>(okResult.Value, "user");

        Assert.Equal("Tạo Reader thành công", message);
        Assert.Equal(1, user?.Id);
    }

    [Fact]
    public async Task UpdateReader_ReturnsOk_WhenNoFileProvided()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.UpdateReader(It.IsAny<UpdateReaderDto>(), 1))
            .ReturnsAsync(new Readers { Id = 1, FullName = "Reader Updated" });

        var controller = new AdminController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var result = await controller.UpdateReader(new UpdateReaderDto { FullName = "Reader Updated" }, null, 1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var user = ControllerTestHelper.GetAnonymousProperty<Readers>(okResult.Value, "user");

        Assert.Equal("Cập nhật Reader thành công", message);
        Assert.Equal("Reader Updated", user?.FullName);
    }

    [Fact]
    public async Task DeleteReader_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.DeleteReader(1))
            .ReturnsAsync(new Readers { Id = 1, FullName = "Reader" });

        var controller = new AdminController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var result = await controller.DeleteReader(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var user = ControllerTestHelper.GetAnonymousProperty<Readers>(okResult.Value, "user");

        Assert.Equal("Xóa Reader thành công", message);
        Assert.Equal(1, user?.Id);
    }
}
