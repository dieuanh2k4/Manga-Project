using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Notification;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.src.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class NotificationController : ApiControllerBase
    {
        private readonly INotificationService _notification;

        public NotificationController(INotificationService notification, ILogger<NotificationController> logger) : base(logger)
        {
            _notification = notification;
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpGet("get-all-notification")]
        public async Task<IActionResult> GetAllNotification()
        {
            try
            {
                var notifications = await _notification.GetAllNotification();

                return Ok(notifications);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
        
        [Authorize(Policy = "AdminOnly")]
        [HttpPost("create-notification")]
        public async Task<IActionResult> CreateNotification(CreateNotificationDto dto)
        {
            try
            {
                var notification = await _notification.CreateNotification(dto);

                return Ok(new
                {
                    message = "Tạo thành công notification",
                    data = notification
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "ReaderOnly")]
        [HttpPost("mark-notification-as-read/{notificationId:int}")]
        public async Task<IActionResult> MarkNotificationAsRead(int notificationId)
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    throw new UnauthorizedAccessException("Cần đăng nhập để đánh dấu đã đọc thông báo");
                }

                await _notification.MarkNotificationReaded(notificationId, userId.Value);

                return Ok(new
                {
                    message = "Đánh dấu đã đọc thông báo thành công"
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "ReaderOnly")]
        [HttpPost("mark-all-unread-notification")]
        public async Task<IActionResult> MarkAllUnreadNotifications()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    throw new UnauthorizedAccessException("Cần đăng nhập để đánh dấu đã đọc tất cả thông báo");
                }

                var markedCount = await _notification.MarkAllUnreadNotifications(userId.Value);

                return Ok(new
                {
                    message = "Đánh dấu đã đọc tất cả thông báo thành công",
                    data = markedCount
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "ReaderOnly")]
        [HttpGet("count-unread-notification")]
        public async Task<IActionResult> CountUnreadNotification()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    throw new UnauthorizedAccessException("Cần đăng nhập để xem số lượng thông báo chưa đọc");
                }

                var unreadCount = await _notification.CountUnreadNotification(userId.Value);

                return Ok(new
                {
                    message = "Lấy số thông báo chưa đọc thành công",
                    data = unreadCount
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}