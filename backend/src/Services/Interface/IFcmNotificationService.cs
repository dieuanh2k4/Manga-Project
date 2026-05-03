using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Notification;
using backend.src.Models;

namespace backend.src.Services.Interface
{
    public interface IFcmNotificationService
    {
        Task<List<Notifications>> GetAllNotification();
        Task<Notifications> SendNotification(CreateNotificationDto dto);
        Task<List<NotificationReads>> GetNotificationByReaderId(int readerid);
        Task MarkNotificationReaded(int notificationId, int userId);
        Task<int> MarkAllUnreadNotifications(int userId);
        Task<int> CountUnreadNotification(int userId);
    }
}