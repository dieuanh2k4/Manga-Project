using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Dtos.Notification
{
    public class CreateNotificationDto
    {
        public string? Title { get; set; }
        public string? Content { get; set; }
        public string? TargetRole { get; set; }
        public int MangaId { get; set; }
    }
}