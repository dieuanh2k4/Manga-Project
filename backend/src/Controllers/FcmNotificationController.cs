using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Notification;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace backend.src.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FcmNotificationController : ApiControllerBase
    {
        private readonly IFcmNotificationService _fcmNotification;

        public FcmNotificationController(IFcmNotificationService fcmNotification, ILogger<FcmNotificationController> logger) : base(logger)
        {
            _fcmNotification = fcmNotification;
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpGet("get-all-notification")]
        public async Task<IActionResult> GetAllNotification()
        {
            try
            {
                var notifications = await _fcmNotification.GetAllNotification();

                return Ok(notifications);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPost("create-notification")]
        public async Task<IActionResult> CreateNotification([FromBody] CreateNotificationDto dto)
        {
            if (dto == null)
            {
                return BadRequest("Yêu cầu dto không được rỗng");
            }

            try
            {
                // Map admin selection to topic when appropriate (do this before validation)
                if (!string.IsNullOrEmpty(dto.TargetRole))
                {
                    if (dto.TargetRole.Equals("All", StringComparison.OrdinalIgnoreCase))
                    {
                        dto.Topic = "all"; // clients should subscribe to 'all'
                    }
                    else if (dto.TargetRole.Equals("LikedManga", StringComparison.OrdinalIgnoreCase))
                    {
                        if (dto.MangaId <= 0)
                        {
                            return BadRequest("MangaId là bắt buộc khi TargetRole = LikedManga");
                        }

                        dto.Topic = $"manga_{dto.MangaId}"; // clients should subscribe to 'manga_{id}' when they like a manga
                    }
                }

                if (string.IsNullOrEmpty(dto.Topic))
                {
                    return BadRequest("Topic là bắt buộc cho chế độ gửi theo nhóm (topic-only). Sử dụng TargetRole hoặc truyền Topic.");
                }

                var notification = await _fcmNotification.SendNotification(dto);

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
        [HttpPost("get-notification-by-readerid")]
        public async Task<IActionResult> GetNotificationByReaderId(int readerid) 
        {
            try
            {
                var notifications = await _fcmNotification.GetNotificationByReaderId(readerid);

                return Ok(notifications);
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

                await _fcmNotification.MarkNotificationReaded(notificationId, userId.Value);

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

                var markedCount = await _fcmNotification.MarkAllUnreadNotifications(userId.Value);

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

                var unreadCount = await _fcmNotification.CountUnreadNotification(userId.Value);

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