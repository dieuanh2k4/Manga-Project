using System;
using System.Collections.Generic;

namespace backend.src.Dtos.Admin
{
    public class ReaderManagementQueryDto
    {
        public string? Search { get; set; }
        public string? Membership { get; set; }
        public string SortBy { get; set; } = "fullName";
        public string SortDir { get; set; } = "desc";
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }

    public class ReaderManagementPageDto
    {
        public List<ReaderManagementItemDto> Items { get; set; } = new();
        public int Total { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
    }

    public class ReaderManagementItemDto
    {
        public int Id { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? UserName { get; set; }
        public string? Phone { get; set; }
        public string? Address { get; set; }
        public string? Gender { get; set; }
        public DateTime RegisteredAt { get; set; }
        public bool IsCommentMuted { get; set; }
        public bool IsBanned { get; set; }
        public string MembershipTier { get; set; } = "Standard";
        public string? TempPassword { get; set; }
    }

    public class CreateReaderManagementDto
    {
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? UserName { get; set; }
        public string? Password { get; set; }
        public string? Gender { get; set; }
        public string? Phone { get; set; }
        public string? Address { get; set; }
    }

    public class UpdateReaderManagementDto
    {
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? UserName { get; set; }
        public string? Gender { get; set; }
        public string? Phone { get; set; }
        public string? Address { get; set; }
    }

    public class ResetPasswordRequestDto
    {
        public string? NewPassword { get; set; }
    }

    public class GrantVipRequestDto
    {
        public int Days { get; set; } = 0;
    }

    public class BulkNotifyRequestDto
    {
        public List<int> ReaderIds { get; set; } = new();
        public string? Title { get; set; }
        public string? Content { get; set; }
    }
}
