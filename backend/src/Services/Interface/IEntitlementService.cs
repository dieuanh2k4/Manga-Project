using System.Threading.Tasks;
using backend.src.Dtos.Package;
using backend.src.Models;

namespace backend.src.Services.Interface
{
    public interface IEntitlementService
    {
        Task<ReaderEntitlementsDto> GetReaderEntitlements(int userId);
        Task<bool> HasPrivilege(int userId, string privilegeCode);
        Task EnsureCanReadChapter(int? userId, Chapters chapter);
    }
}
