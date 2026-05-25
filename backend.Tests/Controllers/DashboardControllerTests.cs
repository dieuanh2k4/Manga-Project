using System.Threading.Tasks;
using backend.src.Controllers;
using backend.src.Dtos.Dashboard;
using backend.src.Services.Interface;
using backend.Tests.TestHelpers;
using Microsoft.AspNetCore.Mvc;
using Moq;
using Xunit;

namespace backend.Tests.Controllers
{
    public class DashboardControllerTests
    {
        [Fact]
        public async Task GetStats_ReturnsOk()
        {
            // Arrange
            var dashboardService = new Mock<IDashboardService>();
            var expectedStats = new DashboardDto
            {
                TotalRevenue = 1500000m,
                ActiveReadersCount = 42,
                TotalViews = 1337,
                VipConversionRate = 12.34
            };

            dashboardService
                .Setup(x => x.GetDashboardStatsAsync())
                .ReturnsAsync(expectedStats);

            var controller = new DashboardController(
                dashboardService.Object,
                ControllerTestHelper.CreateLogger<DashboardController>());

            // Act
            var result = await controller.GetStats();

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(result);
            var payload = Assert.IsType<DashboardDto>(okResult.Value);
            Assert.Equal(1500000m, payload.TotalRevenue);
            Assert.Equal(42, payload.ActiveReadersCount);
            Assert.Equal(1337, payload.TotalViews);
            Assert.Equal(12.34, payload.VipConversionRate);
        }
    }
}
