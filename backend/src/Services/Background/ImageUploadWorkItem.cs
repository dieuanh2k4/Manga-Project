namespace backend.src.Services.Background
{
    // lưu file ảnh tạm thời cho be nén sang webp
    public sealed class ImageUploadWorkItem
    {
        public required string TempFilePath { get; init; }
        public required string BucketName { get; init; }
        public required string ObjectName { get; init; }
        public required string StoragePath { get; init; }
    }
}
