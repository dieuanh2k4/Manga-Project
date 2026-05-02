using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Dtos.Notification
{
    public class CreateNotificationDto
    {
        // public string? DeviceToken { get; set; }
        public string? Title { get; set; }
        public string? Content { get; set; }
        public string? TargetRole { get; set; }
        public int MangaId { get; set; }
        // Topic name for broadcasting to a subscribed group (clients should subscribe to this topic)
        public string? Topic { get; set; }

        // Optional explicit list of device tokens for multicast sends
        // public List<string>? DeviceTokens { get; set; }
    }
}