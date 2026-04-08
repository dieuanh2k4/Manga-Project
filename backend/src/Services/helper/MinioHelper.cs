using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Minio;
using Minio.DataModel.Args;

namespace backend.src.Services.helper
{
    // MinioHelper là lớp hạ tầng cho private storage:
    // - đảm bảo bucket private
    // - chuẩn hóa endpoint
    // - build MinIO client dùng để ký URL ngắn hạn
    public class MinioHelper
    {
        // policy rỗng statement để không public read
        private const string PrivateBucketPolicy = "{\"Version\":\"2012-10-17\",\"Statement\":[]}";

        // PolicyLock + privatePolicyApplied: đồng bộ đa luồng và tránh set policy lặp lại nhiều lần
        private static readonly SemaphoreSlim PolicyLock = new(1, 1);
        private static bool _privatePolicyApplied;

        private readonly IMinioClient _minioClient;
        private readonly IConfiguration _configuration;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly string _bucketName;
        private readonly string _accessKey;
        private readonly string _secretKey;
        private readonly bool _useSsl;

        public MinioHelper(IMinioClient minioClient, IConfiguration configuration, IHttpContextAccessor httpContextAccessor)
        {
            _minioClient = minioClient;
            _configuration = configuration;
            _httpContextAccessor = httpContextAccessor;

            _accessKey = _configuration["Minio:AccessKey"] ?? string.Empty;
            _secretKey = _configuration["Minio:SecretKey"] ?? string.Empty;
            _useSsl = _configuration.GetValue<bool>("Minio:UseSSL");

            var configuredBucket = _configuration["Minio:Bucket"] ?? _configuration["Minio:BucketName"];
            if (string.IsNullOrWhiteSpace(configuredBucket))
            {
                configuredBucket = "mangazone-images";
            }

            // MinIO bucket name must be lowercase.
            _bucketName = configuredBucket.Trim().ToLowerInvariant();
        }
        
        public async Task EnsureBucketIsPrivateAsync()
        {
            // Fast path: policy private đã được apply trong process hiện tại.
            if (_privatePolicyApplied)
            {
                return;
            }

            // Chặn nhiều request cùng lúc set policy trên cùng bucket.
            await PolicyLock.WaitAsync();
            try
            {
                // Double-check sau khi lấy lock để tránh set lặp.
                if (_privatePolicyApplied)
                {
                    return;
                }

                // Nếu bucket chưa có thì tạo bucket mới.
                var bucketExists = await _minioClient.BucketExistsAsync(new BucketExistsArgs().WithBucket(_bucketName));
                if (!bucketExists)
                {
                    await _minioClient.MakeBucketAsync(new MakeBucketArgs().WithBucket(_bucketName));
                }
                
                // Set policy private (không public read object).
                await _minioClient.SetPolicyAsync(
                    new SetPolicyArgs()
                        .WithBucket(_bucketName)
                        .WithPolicy(PrivateBucketPolicy)
                );

                // Đánh dấu đã apply để các request sau return sớm.
                _privatePolicyApplied = true;
            }
            finally
            {
                // Luôn nhả lock kể cả khi xảy ra exception.
                PolicyLock.Release();
            }
        }

        public IMinioClient BuildPresignClient()
        {
            // 1) Ưu tiên endpoint public để frontend có thể truy cập URL đã ký.
            var endpoint = _configuration["Minio:PublicEndpoint"];

            // 2) Xác định SSL theo config public, fallback về config chung.
            var useSsl = _configuration.GetValue<bool?>("Minio:PublicUseSSL") ?? _useSsl;

            if (Uri.TryCreate(endpoint, UriKind.Absolute, out var endpointUri))
            {
                // Nếu endpoint có dạng http(s)://..., normalize về host:port.
                endpoint = NormalizeEndpoint(endpoint);

                // Nếu endpoint có scheme rõ ràng thì ưu tiên scheme đó.
                useSsl = endpointUri.Scheme.Equals("https", StringComparison.OrdinalIgnoreCase);
            }

            var httpContext = _httpContextAccessor.HttpContext;

            if (string.IsNullOrWhiteSpace(endpoint) && httpContext != null)
            {
                // Fallback runtime: lấy host request hiện tại + public port MinIO.
                var request = httpContext.Request;
                var minioPort = _configuration["Minio:PublicPort"] ?? "9004";
                endpoint = $"{request.Host.Host}:{minioPort}";

                // Nếu request vào backend là HTTPS thì dùng HTTPS cho URL ký.
                useSsl = string.Equals(request.Scheme, "https", StringComparison.OrdinalIgnoreCase);
            }

            if (string.IsNullOrWhiteSpace(endpoint))
            {
                // Fallback cuối cùng: dùng endpoint nội bộ MinIO.
                endpoint = _configuration["Minio:Endpoint"] ?? "localhost:9000";
            }

            // Đảm bảo endpoint ở dạng phù hợp cho MinIO client builder.
            endpoint = NormalizeEndpoint(endpoint);

            // 3) Build MinIO client chuyên dùng cho presigned URL.
            var clientBuilder = new MinioClient()
                .WithEndpoint(endpoint)
                .WithCredentials(_accessKey, _secretKey);

            // Bật/tắt SSL theo kết quả quyết định ở các bước trên.
            clientBuilder = clientBuilder.WithSSL(useSsl);

            return clientBuilder.Build();
        }

        // Nếu endpoint có scheme thì chuẩn hóa về host hoặc host:port
        // Nếu đã là host:port thì giữ nguyên
        public static string NormalizeEndpoint(string endpoint)
        {
            var trimmed = endpoint.Trim();

            if (!Uri.TryCreate(trimmed, UriKind.Absolute, out var uri))
            {
                return trimmed;
            }

            return uri.IsDefaultPort ? uri.Host : $"{uri.Host}:{uri.Port}";
        }

        // Phân biệt URL MinIO và URL ngoài
        public static bool MatchesEndpoint(string? endpoint, string host, int port)
        {
            if (string.IsNullOrWhiteSpace(endpoint))
            {
                return false;
            }

            var normalized = endpoint.Trim();
            if (normalized.StartsWith("http://", StringComparison.OrdinalIgnoreCase)
                || normalized.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                if (!Uri.TryCreate(normalized, UriKind.Absolute, out var uri))
                {
                    return false;
                }

                return string.Equals(uri.Host, host, StringComparison.OrdinalIgnoreCase)
                    && uri.Port == port;
            }

            var parts = normalized.Split(':', 2, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 1)
            {
                return string.Equals(parts[0], host, StringComparison.OrdinalIgnoreCase);
            }

            if (!int.TryParse(parts[1], out var endpointPort))
            {
                return false;
            }

            return string.Equals(parts[0], host, StringComparison.OrdinalIgnoreCase)
                && endpointPort == port;
        }
        public bool IsKnownMinioHost(string host, int port)
        {
            var publicEndpoint = _configuration["Minio:PublicEndpoint"];
            var internalEndpoint = _configuration["Minio:Endpoint"];

            if (MatchesEndpoint(publicEndpoint, host, port))
            {
                return true;
            }

            if (MatchesEndpoint(internalEndpoint, host, port))
            {
                return true;
            }

            var publicPort = _configuration["Minio:PublicPort"];
            if (_httpContextAccessor.HttpContext != null && int.TryParse(publicPort, out var parsedPublicPort))
            {
                var requestHost = _httpContextAccessor.HttpContext.Request.Host.Host;
                if (string.Equals(requestHost, host, StringComparison.OrdinalIgnoreCase) && parsedPublicPort == port)
                {
                    return true;
                }
            }

            return false;
        }
        
        // hỗ trợ parse nhiều dạng input 
        public bool TryParseStoragePath(string fileName, out string bucket, out string objectName)
        {
            bucket = _bucketName;
            objectName = string.Empty;

            var input = fileName.Trim();
            if (string.IsNullOrWhiteSpace(input))
            {
                return false;
            }

            if (Uri.TryCreate(input, UriKind.Absolute, out var uri))
            {
                var path = uri.AbsolutePath.Trim('/');
                if (string.IsNullOrWhiteSpace(path))
                {
                    return false;
                }

                var urlParts = path.Split('/', 2, StringSplitOptions.RemoveEmptyEntries);
                if (urlParts.Length == 0)
                {
                    return false;
                }

                if (urlParts.Length == 1)
                {
                    objectName = urlParts[0];
                    return true;
                }

                bucket = urlParts[0].ToLowerInvariant();
                objectName = urlParts[1];
                return true;
            }

            var parts = input.Trim('/').Split('/', 2, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 0)
            {
                return false;
            }

            if (parts.Length == 1)
            {
                objectName = parts[0];
                return true;
            }

            bucket = parts[0].ToLowerInvariant();
            objectName = parts[1];
            return true;
        }

        // Loại ký tự không hợp lệ theo hệ điều hành
        public static string? SanitizeFileName(string? fileName)
        {
            if (string.IsNullOrWhiteSpace(fileName))
            {
                return null;
            }

            var cleaned = Path.GetFileName(fileName).Trim();
            if (string.IsNullOrWhiteSpace(cleaned))
            {
                return null;
            }

            foreach (var invalidChar in Path.GetInvalidFileNameChars())
            {
                cleaned = cleaned.Replace(invalidChar, '_');
            }

            return cleaned;
        }
    }
}