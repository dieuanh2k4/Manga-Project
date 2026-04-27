using System.Collections.Concurrent;
using System.Threading.Channels;
using backend.src.Services.Background;
using backend.src.Services.Interface;

namespace backend.src.Services.Implement
{
    public class ImageUploadBackgroundQueue : IImageUploadBackgroundQueue
    {
        private readonly Channel<ImageUploadWorkItem> _queue;
        private readonly ConcurrentDictionary<string, string> _states;

        public ImageUploadBackgroundQueue()
        {
            // tạo hàng đợi bounded, tối đa 200 job (ảnh)
            var options = new BoundedChannelOptions(200)
            {
                FullMode = BoundedChannelFullMode.Wait,
                SingleReader = true,
                SingleWriter = false
            };
            _queue = Channel.CreateBounded<ImageUploadWorkItem>(options);
            
            // lưu trạng thái
            _states = new ConcurrentDictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        }

        // thêm job (ảnh) vào queue
        public ValueTask QueueBackgroundUploadAsync(ImageUploadWorkItem workItem, CancellationToken cancellationToken = default)
        {
            return _queue.Writer.WriteAsync(workItem, cancellationToken);
        }

        // lấy job(ảnh) ra cho Background Service xử lý
        public ValueTask<ImageUploadWorkItem> DequeueAsync(CancellationToken cancellationToken)
        {
            return _queue.Reader.ReadAsync(cancellationToken);
        }

        // đánh dấu job (ảnh) vừa vào queue
        public void MarkQueued(string storagePath)
        {
            _states[storagePath] = "Queued";
        }

        // đánh dấu job (ảnh) đang xử lý
        public void MarkProcessing(string storagePath)
        {
            _states[storagePath] = "Processing";
        }
        
        // xử lý xong thì xóa trang thái
         public void MarkCompleted(string storagePath)
        {
            _states.TryRemove(storagePath, out _);
        }
        
        // lỗi thì xóa trạng thái
        public void MarkFailed(string storagePath)
        {
            _states.TryRemove(storagePath, out _);
        }

        // kiểm tra xem có còn storagePath còn đang Queued hay Precessing không
        public bool IsInProgress(string storagePath)
        {
            if (!_states.TryGetValue(storagePath, out var state))
            {
                return false;
            }

            return string.Equals(state, "Queued", StringComparison.OrdinalIgnoreCase)
                || string.Equals(state, "Processing", StringComparison.OrdinalIgnoreCase);
        }
    }
}
