using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Notification;
using backend.src.Models;

namespace backend.src.Services.Interface
{
    public interface INotificationService
    {
        Task<List<Notifications>> GetAllNotification();
        Task<Notifications> CreateNotification(CreateNotificationDto dto);
        Task MarkNotificationReaded(int notificationId, int userId);
        Task<int> MarkAllUnreadNotifications(int userId);
        Task<int> CountUnreadNotification(int userId);
    }
}