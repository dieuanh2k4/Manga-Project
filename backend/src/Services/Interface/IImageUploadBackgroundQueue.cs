using backend.src.Services.Background;

namespace backend.src.Services.Interface
{
    public interface IImageUploadBackgroundQueue
    {
        ValueTask QueueBackgroundUploadAsync(ImageUploadWorkItem workItem, CancellationToken cancellationToken = default);
        ValueTask<ImageUploadWorkItem> DequeueAsync(CancellationToken cancellationToken);
        void MarkQueued(string storagePath);
        void MarkProcessing(string storagePath);
        void MarkCompleted(string storagePath);
        void MarkFailed(string storagePath);
        bool IsInProgress(string storagePath);
    }
}
