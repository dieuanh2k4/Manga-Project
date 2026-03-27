using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Services.Interface;
using Minio;
using Minio.DataModel.Args;

namespace Server.src.Services.Implements
{
    public class MinioStorageService : IMinioStorageService
    {
        private readonly IMinioClient _minioClient;
        private readonly IConfiguration _configuration;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly string _bucketName;

        public MinioStorageService(IMinioClient minioClient, IConfiguration configuration, IHttpContextAccessor httpContextAccessor)
        {
            _minioClient = minioClient;
            _configuration = configuration;
            _httpContextAccessor = httpContextAccessor;

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
                // Đảm bảo bucket tồn tại
                var bucketExists = await _minioClient.BucketExistsAsync(
                    new BucketExistsArgs().WithBucket(_bucketName)
                );

                if (!bucketExists)
                {
                    // Tạo bucket mới
                    await _minioClient.MakeBucketAsync(
                        new MakeBucketArgs().WithBucket(_bucketName)
                    );

                    // Set policy public cho bucket để cho phép đọc file
                    var policyJson = @"{
                        ""Version"": ""2012-10-17"",
                        ""Statement"": [
                            {
                                ""Effect"": ""Allow"",
                                ""Principal"": {""AWS"": ""*""},
                                ""Action"": [""s3:GetObject""],
                                ""Resource"": [""arn:aws:s3:::" + _bucketName + @"/*""]
                            }
                        ]
                    }";

                    await _minioClient.SetPolicyAsync(
                        new SetPolicyArgs()
                            .WithBucket(_bucketName)
                            .WithPolicy(policyJson)
                    );
                }

                // Tạo tên file unique
                var fileExtension = Path.GetExtension(file.FileName);
                var fileName = $"{folder}/{Guid.NewGuid()}{fileExtension}";

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
                // fileName có format: bucket/folder/file.jpg
                // Tách bucket và object path
                var parts = fileName.Split('/', 2);
                var bucket = parts.Length > 1 ? parts[0] : _bucketName;
                var objectName = parts.Length > 1 ? parts[1] : fileName;

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

        public string GetImageUrl(string fileName)
        {
            // Nếu đã là URL đầy đủ (http/https), trả về luôn
            if (fileName.StartsWith("http://") || fileName.StartsWith("https://"))
            {
                return fileName;
            }
            
            // fileName có format: bucket/folder/file.jpg hoặc chỉ folder/file.jpg
            // Chỉ cần ghép domain vào
            
            var httpContext = _httpContextAccessor.HttpContext;
            string baseUrl;
            
            if (httpContext != null)
            {
                var request = httpContext.Request;
                var host = request.Host.Host;
                var scheme = request.Scheme;
                
                // MinIO port (9004 từ docker-compose)
                var minioPort = _configuration["Minio:PublicPort"] ?? "9004";
                baseUrl = $"{scheme}://{host}:{minioPort}";
            }
            else
            {
                // Fallback nếu không có HttpContext (background jobs, etc.)
                var endpoint = _configuration["Minio:PublicEndpoint"] ?? "localhost:9004";
                var useSsl = _configuration.GetValue<bool>("Minio:UseSsl");
                var protocol = useSsl ? "https" : "http";
                baseUrl = $"{protocol}://{endpoint}";
            }
            
            // fileName đã chứa bucket name, chỉ cần ghép baseUrl
            return $"{baseUrl}/{fileName}";
        }
    }
}