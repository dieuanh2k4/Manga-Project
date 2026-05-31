using Microsoft.AspNetCore.Http;

namespace backend.src.Services.Interface
{
    public interface IMinioStorageService
    {
        Task<string> UploadImageAsync(IFormFile file, string folder = "images");
        Task<bool> DeleteImageAsync(string fileName);
        Task<string> GetImageUrlAsync(string fileName, int expirySeconds = 300);
        bool TryParseStoragePath(string fileName, out string bucket, out string objectName);
    }
}