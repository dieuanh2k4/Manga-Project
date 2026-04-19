using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace backend.src.Hubs
{
    [Authorize]
    public class NotificationHub : Hub
    {
        // group chung cho toàn bộ user online
        public const string ReaderGroupName = "role-reader"; 
        
        // chuẩn hóa tên group theo từng user
        public static string UserGroupName(int userId) => $"user-{userId}";

        // chạy mỗi khi có 1 connection mới mở thành công
        public override async Task OnConnectedAsync()
        {
            // add mọi reader online vào nhóm "role-reader"
            if (Context.User?.IsInRole("Reader") == true)
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, ReaderGroupName);
            }
            
            // lấy claim NameIdentifier -> parse thành userId
            var userIdValue = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(userIdValue, out var userId))
            {
                // add group riêng user, nghĩa là mỗi user online sẽ có group cá nhân
                await Groups.AddToGroupAsync(Context.ConnectionId, UserGroupName(userId));
            }

            await base.OnConnectedAsync(); // hoàn tất lifecycle
        }
    }
}
