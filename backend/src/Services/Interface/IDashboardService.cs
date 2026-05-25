using System.Threading.Tasks;
using backend.src.Dtos.Dashboard;

namespace backend.src.Services.Interface
{
    public interface IDashboardService
    {
        Task<DashboardDto> GetDashboardStatsAsync();
    }
}
