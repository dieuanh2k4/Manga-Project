using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Notification;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using FirebaseAdmin.Messaging;
using Google.Apis.Util;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace backend.src.Services.Implement
{
    public class FcmNotificationService : IFcmNotificationService
    {
        private static readonly string[] AllReadersRoleAliases =
        {
            "all_readers",
            "tất cả người dùng",
            "tat ca nguoi dung",
            "all readers",
            "all"
        };

        private static readonly string[] FollowedReadersRoleAliases =
        {
            "user_interested_manga",
            "người dùng theo dõi manga",
            "nguoi dung theo doi manga",
            "followed_readers",
            "likedmanga"
        };

        private readonly ApplicationDbContext _context;
        private readonly ILogger<FcmNotificationService> _logger;

        public FcmNotificationService(
            ApplicationDbContext context,
            ILogger<FcmNotificationService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<Notifications>> GetAllNotification()
        {
            var notifications = await _context.Notifications.ToListAsync();

            if (notifications == null)
            {
                throw new Result("Không có thông báo nào trong hệ thống.");
            }

            return notifications;
        }
        
        public async Task<Notifications> SendNotification(CreateNotificationDto dto)
        {
            try
            {
                var data = new Dictionary<string, string>()
                {
                    {"action", dto.Title ?? string.Empty},
                    {"mangaId", dto.MangaId.ToString()},
                    { "click_action", "FLUTTER_NOTIFICATION_CLICK" }
                };

                var androidConfig = new AndroidConfig
                {
                    Priority = Priority.High,
                    TimeToLive = TimeSpan.FromDays(7),
                    Notification = new AndroidNotification
                    {
                        ClickAction = "FLUTTER_NOTIFICATION_CLICK"
                    }
                };

                var apnsConfig = new ApnsConfig
                {
                    Headers = new Dictionary<string, string>
                    {
                        { "apns-priority", "10" },
                        { "apns-expiration", DateTimeOffset.UtcNow.AddDays(7).ToUnixTimeSeconds().ToString() }
                    }
                };

                // Topic-only send (admin -> users via topic). If no topic provided, reject.
                if (!string.IsNullOrEmpty(dto.Topic))
                {
                    var message = new Message
                    {
                        Topic = dto.Topic,
                        Notification = new Notification { Title = dto.Title, Body = dto.Content },
                        Data = data,
                        Android = androidConfig,
                        Apns = apnsConfig
                    };

                    // gửi thông báo thật lên Firebase Cloud Messaging
                    await FirebaseMessaging.DefaultInstance.SendAsync(message);

                    var notification = new Notifications
                    {
                        Title = dto.Title,
                        Content = dto.Content,
                        TargetRole = dto.TargetRole,
                        MangaId = dto.MangaId
                    };

                    await _context.AddAsync(notification);
                    await _context.SaveChangesAsync();

                    // Ghi liên kết vào NotificationReads dựa trên TargetRole
                    await PopulateNotificationReads(notification);

                    return notification;
                }

                throw new Result("Topic là bắt buộc cho chế độ gửi theo nhóm (topic-only)");
            }
            catch (Exception ex)
            {
                throw new Result($"Lỗi gửi thông báo: {ex.Message}");
            }
        }

        private async Task PopulateNotificationReads(Notifications notification)
        {
            List<int> readerIds = new List<int>();

            var normalizedTargetRole = (notification.TargetRole ?? string.Empty).Trim();

            if (AllReadersRoleAliases.Any(alias => string.Equals(alias, normalizedTargetRole, StringComparison.OrdinalIgnoreCase)))
            {
                readerIds = await _context.Readers
                    .Select(r => r.Id)
                    .ToListAsync();
            }
            else if (FollowedReadersRoleAliases.Any(alias => string.Equals(alias, normalizedTargetRole, StringComparison.OrdinalIgnoreCase)))
            {
                readerIds = await _context.Libraries
                    .Where(l => l.MangaId == notification.MangaId)
                    .Select(l => l.ReaderId)
                    .Distinct()
                    .ToListAsync();
            }

            if (readerIds.Count > 0)
            {
                var notificationReads = readerIds
                    .Select(readerId => new NotificationReads
                    {
                        ReaderId = readerId,
                        NotificationId = notification.Id,
                        ReadAt = DateTime.UtcNow,
                        IsRead = false
                        
                    })
                    .ToList();

                await _context.NotificationReads.AddRangeAsync(notificationReads);
                await _context.SaveChangesAsync();
            }
        }

        public async Task<List<NotificationWithReadStateDto>> GetNotificationByReaderId(int userId)
        {
            var reader = await _context.Readers
                .FirstOrDefaultAsync(r => r.UserId == userId || r.Id == userId);

            if (reader == null)
            {
                return new List<NotificationWithReadStateDto>();
            }

            var notifications = await _context.NotificationReads
                .Where(nr => nr.ReaderId == reader.Id)
                .Where(nr => nr.Notification != null)
                .Select(nr => new NotificationWithReadStateDto
                {
                    Id = nr.Notification!.Id,
                    Title = nr.Notification.Title,
                    Content = nr.Notification.Content,
                    TargetRole = nr.Notification.TargetRole,
                    MangaId = nr.Notification.MangaId,
                    CreatedAt = nr.Notification.CreatedAt,
                    IsRead = nr.IsRead
                })
                .OrderByDescending(n => n.CreatedAt)
                .ToListAsync();

            return notifications;
        }

        public async Task MarkNotificationReaded(int notificationId, int userId)
        {
            var reader = await _context.Readers
                .FirstOrDefaultAsync(r => r.UserId == userId);

            if (reader == null)
            {
                throw new Result("Không tìm thấy reader");
            }

            var notification = await _context.Notifications
                .AsNoTracking()
                .FirstOrDefaultAsync(n => n.Id == notificationId);

            if (notification == null)
            {
                throw new Result("Không tìm thấy thông báo");
            }

            var notificationRead = await _context.NotificationReads
                .FirstOrDefaultAsync(nr => nr.ReaderId == reader.Id && nr.NotificationId == notificationId);

            if (notificationRead == null)
            {
                throw new Result("Không tìm thấy bản ghi thông báo");
            }

            notificationRead.IsRead = true;

            _context.NotificationReads.Update(notificationRead);
            await _context.SaveChangesAsync();
        }

        public async Task<int> MarkAllUnreadNotifications(int userId)
        {
            var reader = await _context.Readers
                .FirstOrDefaultAsync(r => r.UserId == userId);

            if (reader == null)
            {
                throw new Result("Không tìm thấy reader");
            }

            var unreadNotifications = await _context.NotificationReads
                .Where(nr => nr.ReaderId == reader.Id && nr.IsRead == false)
                .ToListAsync();

            if (unreadNotifications.Count == 0)
            {
                return 0;
            }

            foreach (var notification in unreadNotifications)
            {
                notification.IsRead = true;
            }

            _context.NotificationReads.UpdateRange(unreadNotifications);
            await _context.SaveChangesAsync();

            return unreadNotifications.Count;
        }

        public async Task<int> CountUnreadNotification(int userId)
        {
            var reader = await _context.Readers
                .FirstOrDefaultAsync(r => r.UserId == userId);

            if (reader == null)
            {
                throw new Result("Không tìm thấy reader");
            }

            var unreadCount = await _context.NotificationReads
                .Where(nr => nr.ReaderId == reader.Id && nr.IsRead == false)
                .CountAsync();

            return unreadCount;
        }
    }
}