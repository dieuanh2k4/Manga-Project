using System;

namespace backend.src.Dtos.Notification
{
    public class NotificationWithReadStateDto
    {
        public int Id { get; set; }
        public string? Title { get; set; }
        public string? Content { get; set; }
        public string? TargetRole { get; set; }
        public int MangaId { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsRead { get; set; }
    }
}