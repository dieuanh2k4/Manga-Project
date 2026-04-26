using System.Security.Claims;
using backend.src.Controllers;
using backend.src.Dtos.Admin;
using backend.src.Dtos.Exceptions;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using backend.Tests.TestHelpers;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace backend.Tests.Controllers;

public class ReaderControllerTests
{
    [Fact]
    public async Task GetInfoReader_ReturnsOk_WhenReaderFound_AndAvatarNeedsResolve()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.GetInfoReader())
            .ReturnsAsync(new List<Readers>
            {
                new()
                {
                    Id = 1,
                    UserId = 10,
                    FullName = "Reader",
                    Email = "reader@example.com",
                    Birth = new DateOnly(2000, 1, 1),
                    Phone = "0900000000",
                    Avatar = "avatar.png"
                }
            });

        minioService
            .Setup(x => x.GetImageUrlAsync("avatar.png", 300))
            .ReturnsAsync("https://cdn/avatar.png");

        var controller = new ReaderController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());
        SetUserId(controller, 10);

        var result = await controller.GetInfoReader();

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<Readers>(okResult.Value);

        Assert.Equal(1, payload.Id);
        Assert.Equal("https://cdn/avatar.png", payload.Avatar);
        minioService.Verify(x => x.GetImageUrlAsync("avatar.png", 300), Times.Once);
    }

    [Fact]
    public async Task GetInfoReader_ReturnsUnauthorized_WhenUserMissingClaim()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        var controller = new ReaderController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());
        controller.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };

        var result = await controller.GetInfoReader();

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(401, objectResult.StatusCode);
        Assert.Equal("Token khong hop le", payload.Message);
    }

    [Fact]
    public async Task GetInfoReader_ReturnsNotFound_WhenReaderNotFound()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.GetInfoReader())
            .ReturnsAsync(new List<Readers>());

        var controller = new ReaderController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());
        SetUserId(controller, 10);

        var result = await controller.GetInfoReader();

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(404, objectResult.StatusCode);
        Assert.Equal("Khong tim thay thong tin Reader", payload.Message);
    }

    [Fact]
    public async Task UpdateReader_ReturnsOk_WhenFileProvidedAndUploadSucceeds()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();
        var file = ControllerTestHelper.CreateFormFile("avatar.png");

        minioService
            .Setup(x => x.UploadImageAsync(It.IsAny<IFormFile>(), "images"))
            .ReturnsAsync("https://cdn/avatar.png");

        adminService
            .Setup(x => x.UpdateReader(It.IsAny<UpdateReaderDto>(), 1))
            .ReturnsAsync(new Readers
            {
                Id = 1,
                UserId = 10,
                FullName = "Reader Updated",
                Email = "reader@example.com",
                Birth = new DateOnly(2000, 1, 1),
                Phone = "0900000000",
                Avatar = "https://cdn/avatar.png"
            });

        var controller = new ReaderController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var dto = new UpdateReaderDto { FullName = "Reader Updated" };
        var result = await controller.UpdateReader(dto, file, 1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var user = ControllerTestHelper.GetAnonymousProperty<Readers>(okResult.Value, "user");

        Assert.Equal("Cập nhật account thành công", message);
        Assert.Equal("Reader Updated", user?.FullName);
    }

    [Fact]
    public async Task UpdateReader_ReturnsOk_WhenUploadFailsAndServiceStillUpdates()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();
        var file = ControllerTestHelper.CreateFormFile("avatar.png");

        minioService
            .Setup(x => x.UploadImageAsync(It.IsAny<IFormFile>(), "images"))
            .ThrowsAsync(new Exception("Upload failed"));

        adminService
            .Setup(x => x.UpdateReader(It.Is<UpdateReaderDto>(d => d.Avatar == null), 1))
            .ReturnsAsync(new Readers
            {
                Id = 1,
                UserId = 10,
                FullName = "Reader Updated",
                Email = "reader@example.com",
                Birth = new DateOnly(2000, 1, 1),
                Phone = "0900000000"
            });

        var controller = new ReaderController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var dto = new UpdateReaderDto { FullName = "Reader Updated", Avatar = "old-avatar" };
        var result = await controller.UpdateReader(dto, file, 1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var user = ControllerTestHelper.GetAnonymousProperty<Readers>(okResult.Value, "user");

        Assert.Equal("Cập nhật account thành công", message);
        Assert.Equal(1, user?.Id);
    }

    [Fact]
    public async Task UpdateReader_ReturnsBadRequest_WhenServiceThrowsResult()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.UpdateReader(It.IsAny<UpdateReaderDto>(), 1))
            .ThrowsAsync(new Result("Update failed"));

        var controller = new ReaderController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var result = await controller.UpdateReader(new UpdateReaderDto(), null, 1);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(400, objectResult.StatusCode);
        Assert.Equal("Update failed", payload.Message);
    }

    [Fact]
    public async Task DeleteReader_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.DeleteReader(1))
            .ReturnsAsync(new Readers
            {
                Id = 1,
                UserId = 10,
                FullName = "Reader",
                Email = "reader@example.com",
                Birth = new DateOnly(2000, 1, 1),
                Phone = "0900000000"
            });

        var controller = new ReaderController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var result = await controller.DeleteReader(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var user = ControllerTestHelper.GetAnonymousProperty<Readers>(okResult.Value, "user");

        Assert.Equal("Xóa account thành công", message);
        Assert.Equal(1, user?.Id);
    }

    [Fact]
    public async Task DeleteReader_ReturnsNotFound_WhenServiceThrowsKeyNotFound()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var adminService = new Mock<IAdminService>();
        var minioService = new Mock<IMinioStorageService>();

        adminService
            .Setup(x => x.DeleteReader(1))
            .ThrowsAsync(new KeyNotFoundException("Reader not found"));

        var controller = new ReaderController(
            dbContext,
            adminService.Object,
            minioService.Object,
            ControllerTestHelper.CreateLogger<AdminController>());

        var result = await controller.DeleteReader(1);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(404, objectResult.StatusCode);
        Assert.Equal("Reader not found", payload.Message);
    }

    private static void SetUserId(ReaderController controller, int userId)
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
