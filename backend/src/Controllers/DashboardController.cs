using System;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace backend.src.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "AdminOnly")]
    public class DashboardController : ApiControllerBase
    {
        private readonly IDashboardService _dashboardService;

        public DashboardController(
            IDashboardService dashboardService,
            ILogger<DashboardController> logger) : base(logger)
        {
            _dashboardService = dashboardService;
        }

        [HttpGet("get-stats")]
        public async Task<IActionResult> GetStats()
        {
            try
            {
                var stats = await _dashboardService.GetDashboardStatsAsync();
                return Ok(stats);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpGet("get-recent-activities")]
        public async Task<IActionResult> GetRecentActivities([FromQuery] int limit = 20)
        {
            try
            {
                var activities = await _dashboardService.GetRecentActivitiesAsync(limit);
                return Ok(activities);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}
