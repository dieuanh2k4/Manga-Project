using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Notification;
using backend.src.Exceptions;
using backend.src.Hubs;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class NotificationService : INotificationService
    {
        private static readonly string[] AllReadersRoleAliases =
        {
            "all_readers",
            "tất cả người dùng",
            "tat ca nguoi dung",
            "all readers"
        };

        private static readonly string[] FollowedReadersRoleAliases =
        {
            "user_interested_manga",
            "người dùng theo dõi manga",
            "nguoi dung theo doi manga",
            "followed_readers"
        };

        private readonly ApplicationDbContext _context;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly ILogger<NotificationService> _logger;

        public NotificationService(
            ApplicationDbContext context,
            IHubContext<NotificationHub> hubContext,
            ILogger<NotificationService> logger)
        {
            _context = context;
            _hubContext = hubContext;
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

        public async Task<Notifications> CreateNotification(CreateNotificationDto dto) 
        {
            if (string.IsNullOrWhiteSpace(dto.Title))
            {
                throw new Result("Tiêu đề thông báo không được để trống");
            }

            if (string.IsNullOrWhiteSpace(dto.Content))
            {
                throw new Result("Nội dung thông báo không được để trống");
            }

            if (string.IsNullOrWhiteSpace(dto.TargetRole))
            {
                throw new Result("Đối tượng nhận thông báo không được để trống");
            }

            var normalizedTargetRole = dto.TargetRole.Trim().ToLower();

            var notification = new Notifications
            {
                Title = dto.Title,
                Content = dto.Content,
                TargetRole = dto.TargetRole,
                MangaId = dto.MangaId
            };

            await _context.AddAsync(notification);
            await _context.SaveChangesAsync();

            if (AllReadersRoleAliases.Contains(normalizedTargetRole))
            {
                try
                {
                    await _hubContext.Clients.Group(NotificationHub.ReaderGroupName).SendAsync("ReceiveNotification", new
                    {
                        notification.Id,
                        notification.Title,
                        notification.TargetRole,
                        notification.Content,
                        notification.MangaId,
                        notification.CreatedAt
                    });
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Gửi realtime notification thất bại");
                }
            } 
            else if (FollowedReadersRoleAliases.Contains(normalizedTargetRole))
            {
                // lấy danh sách các reader lưu manga vào library
                var targetUserIds = await _context.Libraries
                    .Where(l => l.MangaId == notification.MangaId)
                    .Join(
                        _context.Readers,
                        library => library.ReaderId,
                        reader => reader.Id,
                        (library, reader) => reader.UserId)
                    .Distinct() // loại bỏ trùng lặp, đảm bảo mỗi userId chỉ xuất hiện 1 lần để gửi noti
                    .ToListAsync();

                var targetUserGroups = targetUserIds
                    .Select(NotificationHub.UserGroupName)
                    .ToList();

                if (targetUserGroups.Count > 0)
                {
                    try
                    {
                        await _hubContext.Clients.Groups(targetUserGroups).SendAsync("ReceiveNotification", new
                        {
                            notification.Id,
                            notification.Title,
                            notification.TargetRole,
                            notification.Content,
                            notification.MangaId,
                            notification.CreatedAt
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Gửi realtime notification thất bại");
                    }
                }
            };

            return notification;
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

            // danh sách các manga mà reader theo dõi
            var followedMangaIds = _context.Libraries
                .Where(l => l.ReaderId == reader.Id)
                .Select(l => l.MangaId);
            
            // lấy các notification có liên quan đến reader
            var NotificationIds = await _context.Notifications
                .Where(n =>
                    // điều kiện 1: TargetRole là nhóm gửi tất cả các reader
                    AllReadersRoleAliases.Contains((n.TargetRole ?? string.Empty).ToLower())
                    // điều kiện 2: TargetRole là nhóm gửi cho người theo dõi manga 
                    // và MangaId của notification nằm trong followedMangaIds
                    || (FollowedReadersRoleAliases.Contains((n.TargetRole ?? string.Empty).ToLower())
                        && followedMangaIds.Contains(n.MangaId))
                )
                .Select(n => n.Id)
                .ToListAsync();

            if (NotificationIds.Count == 0)
            {
                return 0;
            }

            // danh sách các notification của reader đã đọc
            var readNotificationIds = await _context.NotificationReads
                .Where(nr => nr.ReaderId == reader.Id && NotificationIds.Contains(nr.NotificationId))
                .Select(nr => nr.NotificationId)
                .ToListAsync();
            
            // danh sách notification mà reader chưa đọc
            var unreadNotificationIds = NotificationIds
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

            // danh sách các manga mà reader theo dõi
            var followedMangaIds = _context.Libraries
                .Where(l => l.ReaderId == reader.Id)
                .Select(l => l.MangaId);
            
            // lấy các notification có liên quan đến reader
            var NotificationIds = await _context.Notifications
                .Where(n =>
                    // điều kiện 1: TargetRole là nhóm gửi tất cả các reader
                    AllReadersRoleAliases.Contains((n.TargetRole ?? string.Empty).ToLower())
                    // điều kiện 2: TargetRole là nhóm gửi cho người theo dõi manga 
                    // và MangaId của notification nằm trong followedMangaIds
                    || (FollowedReadersRoleAliases.Contains((n.TargetRole ?? string.Empty).ToLower())
                        && followedMangaIds.Contains(n.MangaId))
                )
                .Select(n => n.Id)
                .ToListAsync();

            if (NotificationIds.Count == 0)
            {
                return 0;
            }

            var readCount = await _context.NotificationReads
                .Where(nr => nr.ReaderId == reader.Id && NotificationIds.Contains(nr.NotificationId))
                .Select(nr => nr.NotificationId)
                .Distinct()
                .CountAsync();

            // trả về các notification chưa đọc
            return NotificationIds.Count - readCount;
        }
    }
}