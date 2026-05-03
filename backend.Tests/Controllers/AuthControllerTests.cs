using backend.src.Controllers;
using backend.src.Dtos.Auth;
using backend.src.Dtos.Exceptions;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using backend.Tests.TestHelpers;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace backend.Tests.Controllers;

public class AuthControllerTests
{
    [Fact]
    public async Task Login_ReturnsOk_WhenAuthenticationSucceeds()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var authService = new Mock<IAuthService>();

        authService
            .Setup(x => x.Login(It.IsAny<LoginRequestDto>()))
            .ReturnsAsync(AuthResultDto.Success(new LoginResponseDto { Token = "token" }));

        var controller = new AuthController(
            dbContext,
            authService.Object,
            ControllerTestHelper.CreateLogger<AuthController>());

        var result = await controller.Login(new LoginRequestDto { UserName = "u", Password = "p" });

        var okResult = Assert.IsType<OkObjectResult>(result);
        var payload = Assert.IsType<AuthResultDto>(okResult.Value);
        Assert.True(payload.IsSuccess);
    }

    [Fact]
    public async Task Login_ReturnsBadRequest_WhenAuthenticationFails()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var authService = new Mock<IAuthService>();

        authService
            .Setup(x => x.Login(It.IsAny<LoginRequestDto>()))
            .ReturnsAsync(AuthResultDto.Fail("Invalid credentials"));

        var controller = new AuthController(
            dbContext,
            authService.Object,
            ControllerTestHelper.CreateLogger<AuthController>());

        var result = await controller.Login(new LoginRequestDto { UserName = "u", Password = "wrong" });

        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        var payload = Assert.IsType<AuthResultDto>(badRequest.Value);
        Assert.False(payload.IsSuccess);
    }

    [Fact]
    public async Task Register_ReturnsOk_WhenRegisterSucceeds()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var authService = new Mock<IAuthService>();
        var createdUser = new Users { Id = 1, UserName = "reader", Role = "Reader" };

        authService
            .Setup(x => x.Register(It.IsAny<RegisterDto>()))
            .ReturnsAsync(createdUser);

        var controller = new AuthController(
            dbContext,
            authService.Object,
            ControllerTestHelper.CreateLogger<AuthController>());

        var result = await controller.Register(new RegisterDto { UserName = "reader", Password = "123" });

        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);

        var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value, "message");
        var user = ControllerTestHelper.GetAnonymousProperty<Users>(okResult.Value, "user");

        Assert.Equal("Đăng ký thành công", message);
        Assert.Equal(1, user?.Id);
    }

    [Fact]
    public async Task Register_ReturnsBadRequest_WhenServiceThrowsResult()
    {
        using var dbContext = ControllerTestHelper.CreateDbContext();
        var authService = new Mock<IAuthService>();

        authService
            .Setup(x => x.Register(It.IsAny<RegisterDto>()))
            .ThrowsAsync(new Result("Register failed"));

        var controller = new AuthController(
            dbContext,
            authService.Object,
            ControllerTestHelper.CreateLogger<AuthController>());

        var result = await controller.Register(new RegisterDto { UserName = "reader" });

        var objectResult = Assert.IsType<ObjectResult>(result);
        var payload = Assert.IsType<ExceptionBody>(objectResult.Value);
        Assert.Equal(400, objectResult.StatusCode);
        Assert.Equal("Register failed", payload.Message);
    }
}
