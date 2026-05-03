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

                    return notification;
                }

                throw new Result("Topic là bắt buộc cho chế độ gửi theo nhóm (topic-only)");
            }
            catch (Exception ex)
            {
                throw new Result($"Lỗi gửi thông báo: {ex.Message}");
            }
        }

        public async Task<List<NotificationReads>> GetNotificationByReaderId(int readerid)
        {
            var notifications = await _context.NotificationReads
                                .Where(n => n.ReaderId == readerid)
                                .ToListAsync();

            if (notifications == null)
            {
                throw new Result("Không có thông báo.");
            }

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

            var checkReaded = await _context.NotificationReads
                .FirstOrDefaultAsync(nr => nr.ReaderId == reader.Id && nr.NotificationId == notificationId);

            if (checkReaded != null)
            {
                return;
            }

            var readState = new NotificationReads
            {
                ReaderId = reader.Id,
                NotificationId = notificationId,
                ReadAt = DateTime.UtcNow
            };

            await _context.NotificationReads.AddAsync(readState);
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

            var notificationIds = await GetRelevantNotificationIds(reader.Id);

            if (notificationIds.Count == 0)
            {
                return 0;
            }

            var readNotificationIds = await _context.NotificationReads
                .Where(nr => nr.ReaderId == reader.Id && notificationIds.Contains(nr.NotificationId))
                .Select(nr => nr.NotificationId)
                .ToListAsync();

            var unreadNotificationIds = notificationIds
                .Except(readNotificationIds)
                .ToList();

            if (unreadNotificationIds.Count == 0)
            {
                return 0;
            }

            var readStates = unreadNotificationIds
                .Select(notificationId => new NotificationReads
                {
                    ReaderId = reader.Id,
                    NotificationId = notificationId,
                    ReadAt = DateTime.UtcNow
                })
                .ToList();

            await _context.NotificationReads.AddRangeAsync(readStates);
            await _context.SaveChangesAsync();

            return unreadNotificationIds.Count;
        }

        public async Task<int> CountUnreadNotification(int userId)
        {
            var reader = await _context.Readers
                .FirstOrDefaultAsync(r => r.UserId == userId);

            if (reader == null)
            {
                throw new Result("Không tìm thấy reader");
            }

            var notificationIds = await GetRelevantNotificationIds(reader.Id);

            if (notificationIds.Count == 0)
            {
                return 0;
            }

            var readCount = await _context.NotificationReads
                .Where(nr => nr.ReaderId == reader.Id && notificationIds.Contains(nr.NotificationId))
                .Select(nr => nr.NotificationId)
                .Distinct()
                .CountAsync();

            return notificationIds.Count - readCount;
        }

        private async Task<List<int>> GetRelevantNotificationIds(int readerId)
        {
            var followedMangaIds = await _context.Libraries
                .Where(l => l.ReaderId == readerId)
                .Select(l => l.MangaId)
                .ToListAsync();

            var notifications = await _context.Notifications
                .Select(n => new
                {
                    n.Id,
                    n.TargetRole,
                    n.MangaId
                })
                .ToListAsync();

            return notifications
                .Where(n =>
                {
                    var normalizedTargetRole = (n.TargetRole ?? string.Empty).Trim();

                    return AllReadersRoleAliases.Any(alias => string.Equals(alias, normalizedTargetRole, StringComparison.OrdinalIgnoreCase))
                        || (FollowedReadersRoleAliases.Any(alias => string.Equals(alias, normalizedTargetRole, StringComparison.OrdinalIgnoreCase))
                            && followedMangaIds.Contains(n.MangaId));
                })
                .Select(n => n.Id)
                .ToList();
        }
    }
}