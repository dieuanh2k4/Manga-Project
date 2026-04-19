using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Models
{
    public class Notifications
    {
        public int Id { get; set; }
        public string? Title { get; set; }
        public string? Content { get; set; }
        public string? TargetRole { get; set; }
        public int MangaId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public bool IsRead { get; set; } = false;

        public List<NotificationReads> NotificationReads { get; set; } = new();
        public List<Manga>? Manga { get; set; }
    }
}