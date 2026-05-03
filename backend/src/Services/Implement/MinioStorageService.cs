using System;
using backend.src.Services.helper;
using backend.src.Services.Background;
using backend.src.Services.Interface;
using Minio;
using Minio.DataModel.Args;

namespace Server.src.Services.Implements
{
    public class MinioStorageService : IMinioStorageService
    {
        public const string ProcessingMessage = "Đang xử lý";

        private readonly MinioHelper _minioHelper;

        private readonly IMinioClient _minioClient;
        private readonly IImageUploadBackgroundQueue _backgroundQueue;
        private readonly IConfiguration _configuration;
        private readonly string _bucketName;
        private readonly string _tempUploadDirectory;

        public MinioStorageService(
            IMinioClient minioClient,
            IConfiguration configuration,
            IHttpContextAccessor httpContextAccessor,
            IImageUploadBackgroundQueue backgroundQueue)
        {
            _minioClient = minioClient;
            _configuration = configuration;
            _backgroundQueue = backgroundQueue;
            _minioHelper = new MinioHelper(minioClient, configuration, httpContextAccessor);

            var configuredBucket = _configuration["Minio:Bucket"] ?? _configuration["Minio:BucketName"];
            if (string.IsNullOrWhiteSpace(configuredBucket))
            {
                configuredBucket = "mangazone-images";
            }

            // MinIO bucket name must be lowercase.
            _bucketName = configuredBucket.Trim().ToLowerInvariant();

            // _tempUploadDirectory = _configuration["ImageProcessing:TempDirectory"]
            //     ?? Path.Combine(Path.GetTempPath(), "projectmanga-temp-uploads");

            var configPath = _configuration["ImageProcessing:TempDirectory"];
            _tempUploadDirectory = string.IsNullOrWhiteSpace(configPath)
                ? Path.Combine(Path.GetTempPath(), "projectmanga-temp-uploads")
                : configPath;
        }

        public async Task<string> UploadImageAsync(IFormFile file, string folder = "images")
        {
            if (file == null || file.Length == 0)
            {
                throw new ArgumentException("File không tồn tại");
            }

            string? tempFilePath = null;

            try
            {
                await _minioHelper.EnsureBucketIsPrivateAsync();

                var normalizedFolder = MinioHelper.NormalizeFolder(folder);
                var finalName = MinioHelper.BuildWebpFileName(file.FileName);
                var objectName = string.IsNullOrWhiteSpace(normalizedFolder)
                    ? finalName
                    : $"{normalizedFolder}/{finalName}";
                var storagePath = $"{_bucketName}/{objectName}";

                Directory.CreateDirectory(_tempUploadDirectory);
                tempFilePath = Path.Combine(
                    _tempUploadDirectory,
                    $"{Guid.NewGuid():N}{Path.GetExtension(file.FileName)}");

                await using (var stream = file.OpenReadStream())
                await using (var tempStream = new FileStream(tempFilePath, FileMode.Create, FileAccess.Write, FileShare.None))
                {
                    await stream.CopyToAsync(tempStream);
                }

                _backgroundQueue.MarkQueued(storagePath);

                // tạo file ảnh tạm thời để chờ be nén sang .webp
                var workItem = new ImageUploadWorkItem
                {
                    TempFilePath = tempFilePath,
                    BucketName = _bucketName,
                    ObjectName = objectName,
                    StoragePath = storagePath
                };

                await _backgroundQueue.QueueBackgroundUploadAsync(workItem);

                // Trả object key để lưu DB ngay, ảnh thực tế sẽ được xử lý/ngầm upload bởi BackgroundService.
                return storagePath;
            }
            catch (Exception ex)
            {
                if (!string.IsNullOrWhiteSpace(tempFilePath) && File.Exists(tempFilePath))
                {
                    try
                    {
                        File.Delete(tempFilePath);
                    }
                    catch
                    {
                        // Ignore cleanup failures.
                    }
                }

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

            var storagePath = $"{bucket}/{objectName}";
            if (_backgroundQueue.IsInProgress(storagePath))
            {
                return ProcessingMessage;
            }

            if (!await _minioHelper.ObjectExistsAsync(bucket, objectName))
            {
                return ProcessingMessage;
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