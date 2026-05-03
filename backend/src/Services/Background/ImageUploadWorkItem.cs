namespace backend.src.Services.Background
{
    // lưu file ảnh tạm thời cho be nén sang webp
    public sealed class ImageUploadWorkItem
    {
        // đường dẫn file gốc đang nằm tạm trên disk
        public required string TempFilePath { get; init; }
        // bucket MinIO
        public required string BucketName { get; init; }
        // Object key đích, đã là .webp
        public required string ObjectName { get; init; }
        // đường dẫn lưu trong DB
        public required string StoragePath { get; init; }
    }
}
