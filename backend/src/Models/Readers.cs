using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Models
{
    public class Readers
    {
        public int Id { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? Avatar { get; set; }
        public bool IsPremium { get; set; } = false; // trạng thái tài khoản
        public DateOnly Birth { get; set; }
        public string? Gender { get; set; }
        public string? Phone { get; set; }
        public string? Address { get; set; }
        public int UserId { get; set; }

        public Libraries? Libraries { get; set; }
        public List<Ratings>? Ratings { get; set; }
        public List<History>? History { get; set; }
        public Users? Users { get; set; }
    }
}