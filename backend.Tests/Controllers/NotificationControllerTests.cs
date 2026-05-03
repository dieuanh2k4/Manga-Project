using System.Security.Claims;
using backend.src.Controllers;
using backend.src.Dtos.Exceptions;
using backend.src.Dtos.Notification;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using backend.Tests.TestHelpers;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace backend.Tests.Controllers;

public class NotificationControllerTests
{
    [Fact]
    public async Task GetAllNotification_ReturnsOk()
    {
        var notificationService = new Mock<INotificationService>();

        notificationService
            .Setup(x => x.GetAllNotification())
            .ReturnsAsync(new List<Notifications>
            {
                new() { Id = 1, Title = "New chapter", Content = "Available now", TargetRole = "Reader" }
            });

        var controller = new NotificationController(notificationService.Object, ControllerTestHelper.CreateLogger<NotificationController>());

        var result = await controller.GetAllNotification();

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<List<Notifications>>(okResult.Value);
        Assert.Single(payload);
    }

    [Fact]
    public async Task GetAllNotification_ReturnsInternalServerError_WhenServiceThrowsUnexpected()
    {
        var notificationService = new Mock<INotificationService>();

        notificationService
            .Setup(x => x.GetAllNotification())
            .ThrowsAsync(new Exception("Boom"));

        var controller = new NotificationController(notificationService.Object, ControllerTestHelper.CreateLogger<NotificationController>());

        var result = await controller.GetAllNotification();

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(500, objectResult.StatusCode);
        Assert.Equal("An unexpected error occurred.", payload.Message);
    }

    [Fact]
    public async Task CreateNotification_ReturnsOk()
    {
        var notificationService = new Mock<INotificationService>();

        notificationService
            .Setup(x => x.CreateNotification(It.IsAny<CreateNotificationDto>()))
            .ReturnsAsync(new Notifications { Id = 1, Title = "Notice", Content = "Body", TargetRole = "Reader" });

        var controller = new NotificationController(notificationService.Object, ControllerTestHelper.CreateLogger<NotificationController>());

        var result = await controller.CreateNotification(new CreateNotificationDto { Title = "Notice", Content = "Body", TargetRole = "Reader" });

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<Notifications>(okResult.Value, "data");

        Assert.Equal("Tạo thành công notification", message);
        Assert.Equal(1, data?.Id);
    }

    [Fact]
    public async Task CreateNotification_ReturnsBadRequest_WhenServiceThrowsResult()
    {
        var notificationService = new Mock<INotificationService>();

        notificationService
            .Setup(x => x.CreateNotification(It.IsAny<CreateNotificationDto>()))
            .ThrowsAsync(new Result("Create notification failed"));

        var controller = new NotificationController(notificationService.Object, ControllerTestHelper.CreateLogger<NotificationController>());

        var result = await controller.CreateNotification(new CreateNotificationDto());

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(400, objectResult.StatusCode);
        Assert.Equal("Create notification failed", payload.Message);
    }

    [Fact]
    public async Task MarkNotificationAsRead_ReturnsOk_WhenAuthenticated()
    {
        var notificationService = new Mock<INotificationService>();

        notificationService
            .Setup(x => x.MarkNotificationReaded(10, 1))
            .Returns(Task.CompletedTask);

        var controller = new NotificationController(notificationService.Object, ControllerTestHelper.CreateLogger<NotificationController>());
        SetUserId(controller, 1);

        var result = await controller.MarkNotificationAsRead(10);

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        Assert.Equal("Đánh dấu đã đọc thông báo thành công", message);

        notificationService.Verify(x => x.MarkNotificationReaded(10, 1), Times.Once);
    }

    [Fact]
    public async Task MarkNotificationAsRead_ReturnsUnauthorized_WhenUserMissingClaim()
    {
        var notificationService = new Mock<INotificationService>();
        var controller = new NotificationController(notificationService.Object, ControllerTestHelper.CreateLogger<NotificationController>());
        controller.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };

        var result = await controller.MarkNotificationAsRead(10);

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(401, objectResult.StatusCode);
        Assert.Equal("Cần đăng nhập để đánh dấu đã đọc thông báo", payload.Message);
    }

    [Fact]
    public async Task MarkAllUnreadNotifications_ReturnsOk_WhenAuthenticated()
    {
        var notificationService = new Mock<INotificationService>();

        notificationService
            .Setup(x => x.MarkAllUnreadNotifications(1))
            .ReturnsAsync(5);

        var controller = new NotificationController(notificationService.Object, ControllerTestHelper.CreateLogger<NotificationController>());
        SetUserId(controller, 1);

        var result = await controller.MarkAllUnreadNotifications();

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<int>(okResult.Value, "data");

        Assert.Equal("Đánh dấu đã đọc tất cả thông báo thành công", message);
        Assert.Equal(5, data);
    }

    [Fact]
    public async Task MarkAllUnreadNotifications_ReturnsUnauthorized_WhenUserMissingClaim()
    {
        var notificationService = new Mock<INotificationService>();
        var controller = new NotificationController(notificationService.Object, ControllerTestHelper.CreateLogger<NotificationController>());
        controller.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };

        var result = await controller.MarkAllUnreadNotifications();

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(401, objectResult.StatusCode);
        Assert.Equal("Cần đăng nhập để đánh dấu đã đọc tất cả thông báo", payload.Message);
    }

    [Fact]
    public async Task CountUnreadNotification_ReturnsOk_WhenAuthenticated()
    {
        var notificationService = new Mock<INotificationService>();

        notificationService
            .Setup(x => x.CountUnreadNotification(1))
            .ReturnsAsync(2);

        var controller = new NotificationController(notificationService.Object, ControllerTestHelper.CreateLogger<NotificationController>());
        SetUserId(controller, 1);

        var result = await controller.CountUnreadNotification();

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var data = ControllerTestHelper.GetAnonymousProperty<int>(okResult.Value, "data");

        Assert.Equal("Lấy số thông báo chưa đọc thành công", message);
        Assert.Equal(2, data);
    }

    [Fact]
    public async Task CountUnreadNotification_ReturnsUnauthorized_WhenUserMissingClaim()
    {
        var notificationService = new Mock<INotificationService>();
        var controller = new NotificationController(notificationService.Object, ControllerTestHelper.CreateLogger<NotificationController>());
        controller.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };

        var result = await controller.CountUnreadNotification();

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(401, objectResult.StatusCode);
        Assert.Equal("Cần đăng nhập để xem số lượng thông báo chưa đọc", payload.Message);
    }

    private static void SetUserId(NotificationController controller, int userId)
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
