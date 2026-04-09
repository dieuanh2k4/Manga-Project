using Microsoft.AspNetCore.Http;

namespace backend.src.Services.Interface
{
    public interface IMinioStorageService
    {
        Task<string> UploadImageAsync(IFormFile file, string folder = "images");
        Task<bool> DeleteImageAsync(string fileName);
        Task<string> GetImageUrlAsync(string fileName, int expirySeconds = 300);
    }
}