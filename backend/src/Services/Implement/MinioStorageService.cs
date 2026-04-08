using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Services.helper;
using backend.src.Services.Interface;
using Minio;
using Minio.DataModel.Args;

namespace Server.src.Services.Implements
{
    public class MinioStorageService : IMinioStorageService
    {
        private readonly MinioHelper _minioHelper;

        private readonly IMinioClient _minioClient;
        private readonly IConfiguration _configuration;
        private readonly string _bucketName;

        public MinioStorageService(IMinioClient minioClient, IConfiguration configuration, IHttpContextAccessor httpContextAccessor)
        {
            _minioClient = minioClient;
            _configuration = configuration;
            _minioHelper = new MinioHelper(minioClient, configuration, httpContextAccessor);

            var configuredBucket = _configuration["Minio:Bucket"] ?? _configuration["Minio:BucketName"];
            if (string.IsNullOrWhiteSpace(configuredBucket))
            {
                configuredBucket = "mangazone-images";
            }

            // MinIO bucket name must be lowercase.
            _bucketName = configuredBucket.Trim().ToLowerInvariant();
        }

        public async Task<string> UploadImageAsync(IFormFile file, string folder = "images")
        {
            if (file == null || file.Length == 0)
            {
                throw new ArgumentException("File không tồn tại");
            }

            try
            {
                await _minioHelper.EnsureBucketIsPrivateAsync();

                // Nếu có customFileName thì dùng tên đó; nếu không thì dùng đúng tên file upload.
                var fileExtension = Path.GetExtension(file.FileName);
                var effectiveName = string.IsNullOrWhiteSpace(file.FileName)
                    ? "page"
                    : file.FileName;

                var sanitizedName = MinioHelper.SanitizeFileName(effectiveName);
                if (!string.IsNullOrWhiteSpace(sanitizedName) && string.IsNullOrWhiteSpace(Path.GetExtension(sanitizedName)))
                {
                    sanitizedName += fileExtension;
                }

                var finalName = string.IsNullOrWhiteSpace(sanitizedName)
                    ? $"{Guid.NewGuid()}{fileExtension}"
                    : sanitizedName;

                // Use a stable object key so same-name uploads overwrite existing objects.
                var fileName = $"{folder}/{finalName}";

                // Upload file
                using var stream = file.OpenReadStream();
                var putObjectArgs = new PutObjectArgs()
                    .WithBucket(_bucketName)
                    .WithObject(fileName)
                    .WithStreamData(stream)
                    .WithObjectSize(file.Length)
                    .WithContentType(file.ContentType);

                await _minioClient.PutObjectAsync(putObjectArgs);

                // Trả về bucket/fileName để lưu trong DB
                return $"{_bucketName}/{fileName}";
            }
            catch (Exception ex)
            {
                throw new Exception($"Lỗi khi upload file: {ex.Message}", ex);
            }
        }

        public async Task<bool> DeleteImageAsync(string fileName)
        {
            try
            {
                if (!_minioHelper.TryParseStoragePath(fileName, out var bucket, out var objectName))
                {
                    return false;
                }

                var removeObjectArgs = new RemoveObjectArgs()
                    .WithBucket(bucket)
                    .WithObject(objectName);

                await _minioClient.RemoveObjectAsync(removeObjectArgs);
                return true;
            }
            catch
            {
                return false;
            }
        }

        public async Task<string> GetImageUrlAsync(string fileName, int expirySeconds = 300)
        {
            // 1) Input rỗng thì trả nguyên để tránh xử lý thừa.
            if (string.IsNullOrWhiteSpace(fileName))
            {
                return fileName;
            }

            // 2) Đảm bảo bucket đang ở trạng thái private trước khi cấp URL ký.
            await _minioHelper.EnsureBucketIsPrivateAsync();

            // 3) Nếu là absolute URL nhưng không thuộc MinIO hiện tại, giữ nguyên.
            // Điều này giúp tương thích dữ liệu cũ/ảnh ngoài hệ thống (example.com, CDN khác...).
            if (Uri.TryCreate(fileName, UriKind.Absolute, out var absoluteUri)
                && !_minioHelper.IsKnownMinioHost(absoluteUri.Host, absoluteUri.Port))
            {
                return fileName;
            }

            // 4) Parse về bucket/objectName từ các dạng input khác nhau.
            if (!_minioHelper.TryParseStoragePath(fileName, out var bucket, out var objectName))
            {
                return fileName;
            }

            // 5) Giới hạn TTL an toàn để URL không sống quá lâu.
            var safeExpirySeconds = Math.Clamp(expirySeconds, 60, 300);

            // 6) Build client presign theo endpoint public để frontend truy cập được.
            var presignClient = _minioHelper.BuildPresignClient();
            var args = new PresignedGetObjectArgs()
                .WithBucket(bucket)
                .WithObject(objectName)
                .WithExpiry(safeExpirySeconds);

            // 7) Trả signed URL ngắn hạn thay vì link public cố định.
            return await presignClient.PresignedGetObjectAsync(args);
        }
    }
}