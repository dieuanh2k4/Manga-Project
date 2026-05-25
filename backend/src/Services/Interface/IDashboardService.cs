using System.Collections.Generic;
using System.Threading.Tasks;
using backend.src.Dtos.Dashboard;

namespace backend.src.Services.Interface
{
    public interface IDashboardService
    {
        Task<DashboardDto> GetDashboardStatsAsync();
        Task<List<RecentActivityDto>> GetRecentActivitiesAsync(int limit = 20);
    }
}
