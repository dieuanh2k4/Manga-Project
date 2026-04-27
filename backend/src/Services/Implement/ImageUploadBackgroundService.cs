using backend.src.Configurations;
using backend.src.Services.Background;
using backend.src.Services.helper;
using backend.src.Services.Interface;
using Minio;
using Minio.DataModel.Args;
using Microsoft.Extensions.Options;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Webp;
using SixLabors.ImageSharp.Processing;

namespace backend.src.Services.Implement
{
    public class ImageUploadBackgroundService : BackgroundService
    {
        private readonly IImageUploadBackgroundQueue _queue;
        private readonly IMinioClient _minioClient;
        private readonly MinioHelper _minioHelper;
        private readonly ImageProcessingOptions _options;
        private readonly ILogger<ImageUploadBackgroundService> _logger;

        public ImageUploadBackgroundService(
            IImageUploadBackgroundQueue queue,
            IMinioClient minioClient,
            IConfiguration configuration,
            IHttpContextAccessor httpContextAccessor,
            IOptions<ImageProcessingOptions> options,
            ILogger<ImageUploadBackgroundService> logger)
        {
            _queue = queue;
            _minioClient = minioClient;
            _options = options.Value;
            _logger = logger;
            _minioHelper = new MinioHelper(minioClient, configuration, httpContextAccessor);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                ImageUploadWorkItem? workItem = null;

                try
                {
                    // chờ lấy job(ảnh) từ queue ra để xử lý
                    workItem = await _queue.DequeueAsync(stoppingToken);
                    // đánh dấu đang xử lý
                    _queue.MarkProcessing(workItem.StoragePath);

                    // await ProcessAndUploadAsync(workItem, stoppingToken);

                    // Gọi xử lý (nén ảnh, up lên minio)
                    // đảm bảo bucket private
                    await _minioHelper.EnsureBucketIsPrivateAsync();

                    // Đọc cấu hình và đặt ngưỡng ảnh an toàn width/height/quality
                    var targetWidth = Math.Max(64, _options.ResizeWidth);
                    var targetHeight = Math.Max(64, _options.ResizeHeight);
                    var quality = Math.Clamp(_options.WebpQuality, 1, 100);

                    // mở file tạm và load ảnh
                    await using var sourceStream = File.OpenRead(workItem.TempFilePath);
                    using var image = await Image.LoadAsync(sourceStream, stoppingToken);

                    image.Mutate(context =>
                    {
                        
                        // context.AutoOrient();
                        // resize giữ tỉ lệ bằng ResizeMode.Max
                        context.Resize(new ResizeOptions
                        {
                            Mode = ResizeMode.Max,
                            Size = new Size(targetWidth, targetHeight),
                            Sampler = KnownResamplers.Lanczos3
                        });
                    });

                    // encode sang webp với quantity cấu hình
                    await using var output = new MemoryStream();
                    var encoder = new WebpEncoder { Quality = quality };
                    await image.SaveAsync(output, encoder, stoppingToken);

                    // đưa con trỏ của MemoryStream về đầu stream trước khi upload cho minio đọc dl
                    output.Position = 0;

                    // upload lên minio
                    var putObjectArgs = new PutObjectArgs()
                        .WithBucket(workItem.BucketName)
                        .WithObject(workItem.ObjectName)
                        .WithStreamData(output)
                        .WithObjectSize(output.Length)
                        .WithContentType("image/webp");

                    await _minioClient.PutObjectAsync(putObjectArgs);

                    // đánh dấu hoàn thành
                    _queue.MarkCompleted(workItem.StoragePath);
                }
                // nếu app shutdown thì thoát vòng lặp
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    break;
                }
                catch (Exception ex)
                {
                    // lỗi thì đánh dấu lỗi
                    if (workItem != null)
                    {
                        _queue.MarkFailed(workItem.StoragePath);
                    }

                    _logger.LogError(ex, "Background image upload failed.");
                }
                finally
                {
                    // thành công hay lỗi thì luôn xóa file tạm
                    if (workItem != null)
                    {
                        TryDeleteTempFile(workItem.TempFilePath);
                    }
                }
            }
        }

        private static void TryDeleteTempFile(string tempFilePath)
        {
            if (File.Exists(tempFilePath))
            {
                File.Delete(tempFilePath);
            }
        }

        // xử lý ảnh
        // private async Task ProcessAndUploadAsync(ImageUploadWorkItem workItem, CancellationToken cancellationToken)
        // {
        //     // đảm bảo bucket private
        //     await _minioHelper.EnsureBucketIsPrivateAsync();

        //     // Đọc cấu hình và đặt ngưỡng ảnh an toàn width/height/quality
        //     var targetWidth = Math.Max(64, _options.ResizeWidth);
        //     var targetHeight = Math.Max(64, _options.ResizeHeight);
        //     var quality = Math.Clamp(_options.WebpQuality, 1, 100);

        //     // mở file tạm và load ảnh
        //     await using var sourceStream = File.OpenRead(workItem.TempFilePath);
        //     using var image = await Image.LoadAsync(sourceStream, cancellationToken);

        //     image.Mutate(context =>
        //     {
                
        //         // context.AutoOrient();
        //         // resize giữ tỉ lệ bằng ResizeMode.Max
        //         context.Resize(new ResizeOptions
        //         {
        //             Mode = ResizeMode.Max,
        //             Size = new Size(targetWidth, targetHeight),
        //             Sampler = KnownResamplers.Lanczos3
        //         });
        //     });

        //     // encode sang webp với quantity cấu hình
        //     await using var output = new MemoryStream();
        //     var encoder = new WebpEncoder { Quality = quality };
        //     await image.SaveAsync(output, encoder, cancellationToken);

        //     // đưa con trỏ của MemoryStream về đầu stream trước khi upload cho minio đọc dl
        //     output.Position = 0;

        //     // upload lên minio
        //     var putObjectArgs = new PutObjectArgs()
        //         .WithBucket(workItem.BucketName)
        //         .WithObject(workItem.ObjectName)
        //         .WithStreamData(output)
        //         .WithObjectSize(output.Length)
        //         .WithContentType("image/webp");

        //     await _minioClient.PutObjectAsync(putObjectArgs);
        // }

    }
}
