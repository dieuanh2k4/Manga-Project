using System.Security.Claims;
using backend.src.Controllers;
using backend.src.Dtos.Exceptions;
using backend.src.Dtos.Package;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using backend.Tests.TestHelpers;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace backend.Tests.Controllers;

public class PackageControllerTests
{
    [Fact]
    public async Task GetAllPackge_ReturnsOk_WhenHasPackages()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var packageService = new Mock<IPackageService>();
        var entitlementService = new Mock<IEntitlementService>();

        dbContext.Packages.Add(new Packages
        {
            Id = 1,
            Title = "VIP",
            Price = 99000,
            DurationDays = 30,
            Previlages = new List<Previlages>
            {
                new() { Id = 1, Content = "Read premium" }
            }
        });
        await dbContext.SaveChangesAsync();

        var controller = new PackageController(
            dbContext,
            packageService.Object,
            entitlementService.Object,
            ControllerTestHelper.CreateLogger<PackageController>());

        var result = await controller.GetAllPackge();

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<object>(okResult.Value, "data");

        Assert.Equal("Lấy package thành công", message);
        Assert.NotNull(data);
    }

    [Fact]
    public async Task GetAllPackge_ReturnsBadRequest_WhenNoPackage()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var packageService = new Mock<IPackageService>();
        var entitlementService = new Mock<IEntitlementService>();

        var controller = new PackageController(
            dbContext,
            packageService.Object,
            entitlementService.Object,
            ControllerTestHelper.CreateLogger<PackageController>());

        var result = await controller.GetAllPackge();

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(400, objectResult.StatusCode);
        Assert.Equal("Chưa có package nào", payload.Message);
    }

    [Fact]
    public async Task CreatePackage_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var packageService = new Mock<IPackageService>();
        var entitlementService = new Mock<IEntitlementService>();

        packageService
            .Setup(x => x.CreatePackage(It.IsAny<CreatePackageDto>()))
            .ReturnsAsync(new Packages { Id = 1, Title = "VIP", Price = 99000, DurationDays = 30 });

        var controller = new PackageController(
            dbContext,
            packageService.Object,
            entitlementService.Object,
            ControllerTestHelper.CreateLogger<PackageController>());

        var result = await controller.CreatePackage(new CreatePackageDto { Title = "VIP", Price = 99000, DurationDays = 30 });

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Packages>(okResult.Value, "data");

        Assert.Equal("Tạo package thành công", message);
        Assert.Equal(1, data?.Id);
    }

    [Fact]
    public async Task CreatePackage_ReturnsBadRequest_WhenServiceThrowsResult()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var packageService = new Mock<IPackageService>();
        var entitlementService = new Mock<IEntitlementService>();

        packageService
            .Setup(x => x.CreatePackage(It.IsAny<CreatePackageDto>()))
            .ThrowsAsync(new Result("Create package failed"));

        var controller = new PackageController(
            dbContext,
            packageService.Object,
            entitlementService.Object,
            ControllerTestHelper.CreateLogger<PackageController>());

        var result = await controller.CreatePackage(new CreatePackageDto());

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(400, objectResult.StatusCode);
        Assert.Equal("Create package failed", payload.Message);
    }

    [Fact]
    public async Task UpdatePackage_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var packageService = new Mock<IPackageService>();
        var entitlementService = new Mock<IEntitlementService>();

        packageService
            .Setup(x => x.UpdatePackage(It.IsAny<UpdatePackageDto>(), 1))
            .ReturnsAsync(new Packages { Id = 1, Title = "VIP Updated", Price = 120000, DurationDays = 60 });

        var controller = new PackageController(
            dbContext,
            packageService.Object,
            entitlementService.Object,
            ControllerTestHelper.CreateLogger<PackageController>());

        var result = await controller.UpdatePackage(new UpdatePackageDto { Title = "VIP Updated", Price = 120000, DurationDays = 60 }, 1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Packages>(okResult.Value, "data");

        Assert.Equal("Cập nhật package thành công", message);
        Assert.Equal("VIP Updated", data?.Title);
    }

    [Fact]
    public async Task DeletePackage_ReturnsOk()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var packageService = new Mock<IPackageService>();
        var entitlementService = new Mock<IEntitlementService>();

        packageService
            .Setup(x => x.DeletePackage(1))
            .ReturnsAsync(new Packages { Id = 1, Title = "VIP", Price = 99000, DurationDays = 30 });

        var controller = new PackageController(
            dbContext,
            packageService.Object,
            entitlementService.Object,
            ControllerTestHelper.CreateLogger<PackageController>());

        var result = await controller.DeletePackage(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Packages>(okResult.Value, "data");

        Assert.Equal("Xóa package thành công", message);
        Assert.Equal(1, data?.Id);
    }

    [Fact]
    public async Task PurchasePackage_ReturnsOk_WhenAuthenticated()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var packageService = new Mock<IPackageService>();
        var entitlementService = new Mock<IEntitlementService>();

        packageService
            .Setup(x => x.PurchasePackage(1, 10))
            .ReturnsAsync(new ReaderPackageDto
            {
                PurchaseId = 99,
                PackageId = 1,
                PackageTitle = "VIP",
                PackagePrice = 99000,
                PackageDurationDays = 30,
                PurchasedAt = DateTime.UtcNow
            });

        entitlementService
            .Setup(x => x.GetReaderEntitlements(10))
            .ReturnsAsync(new ReaderEntitlementsDto
            {
                ReaderId = 10,
                HasActivePackage = true,
                CanReadPremium = true
            });

        var controller = new PackageController(
            dbContext,
            packageService.Object,
            entitlementService.Object,
            ControllerTestHelper.CreateLogger<PackageController>());
        SetUserId(controller, 10);

        var result = await controller.PurchasePackage(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<object>(okResult.Value, "data");
        var purchase = ControllerTestHelper.GetAnonymousProperty<ReaderPackageDto>(data!, "purchase");
        var entitlements = ControllerTestHelper.GetAnonymousProperty<ReaderEntitlementsDto>(data!, "entitlements");

        Assert.Equal("Mua package thành công", message);
        Assert.Equal(99, purchase?.PurchaseId);
        Assert.Equal(10, entitlements?.ReaderId);
    }

    [Fact]
    public async Task PurchasePackage_ReturnsUnauthorized_WhenUserMissingClaim()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var packageService = new Mock<IPackageService>();
        var entitlementService = new Mock<IEntitlementService>();

        var controller = new PackageController(
            dbContext,
            packageService.Object,
            entitlementService.Object,
            ControllerTestHelper.CreateLogger<PackageController>());
        controller.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };

        var result = await controller.PurchasePackage(1);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(401, objectResult.StatusCode);
        Assert.Equal("Không xác định được người dùng", payload.Message);
    }

    [Fact]
    public async Task GetMyEntitlements_ReturnsOk_WhenAuthenticated()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var packageService = new Mock<IPackageService>();
        var entitlementService = new Mock<IEntitlementService>();

        entitlementService
            .Setup(x => x.GetReaderEntitlements(10))
            .ReturnsAsync(new ReaderEntitlementsDto
            {
                ReaderId = 10,
                HasActivePackage = true,
                CanReadPremium = true
            });

        var controller = new PackageController(
            dbContext,
            packageService.Object,
            entitlementService.Object,
            ControllerTestHelper.CreateLogger<PackageController>());
        SetUserId(controller, 10);

        var result = await controller.GetMyEntitlements();

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<ReaderEntitlementsDto>(okResult.Value, "data");

        Assert.Equal("Lấy đặc quyền hiện tại thành công", message);
        Assert.Equal(10, data?.ReaderId);
    }

    [Fact]
    public async Task GetMyEntitlements_ReturnsUnauthorized_WhenUserMissingClaim()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var packageService = new Mock<IPackageService>();
        var entitlementService = new Mock<IEntitlementService>();

        var controller = new PackageController(
            dbContext,
            packageService.Object,
            entitlementService.Object,
            ControllerTestHelper.CreateLogger<PackageController>());
        controller.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };

        var result = await controller.GetMyEntitlements();

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(401, objectResult.StatusCode);
        Assert.Equal("Không xác định được người dùng", payload.Message);
    }

    private static void SetUserId(PackageController controller, int userId)
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
