using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Models
{
    public class NotificationReads
    {
        public int Id { get; set; }
        public int ReaderId { get; set; }
        public int NotificationId { get; set; }
        public DateTime ReadAt { get; set; } = DateTime.UtcNow;

        public Readers? Reader { get; set; }
        public Notifications? Notification { get; set; }
    }
}