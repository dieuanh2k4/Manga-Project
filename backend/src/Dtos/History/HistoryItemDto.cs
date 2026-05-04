using System;

namespace backend.src.Dtos.History
{
    public class HistoryItemDto
    {
        public int MangaId { get; set; }
        public int LastChapterId { get; set; }
        public int LastPageId { get; set; }
        public bool IsCompleted { get; set; }
        public TimeOnly UpdateAt { get; set; }

        public string? MangaTitle { get; set; }
        public string? MangaThumbnail { get; set; }
    }
}
