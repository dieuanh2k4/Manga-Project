using Microsoft.AspNetCore.Http;

namespace backend.src.Services.Interface
{
    public interface IMinioStorageService
    {
        Task<string> UploadImageAsync(IFormFile file, string folder = "images");
        Task<bool> DeleteImageAsync(string fileName);
        string GetImageUrl(string fileName);
    }
}