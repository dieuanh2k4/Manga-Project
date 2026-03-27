using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Models
{
    public class Admin
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public DateOnly Birth { get; set; }
        public string? Gender { get; set; }
        public string? Email { get; set; }
        public string? Avatar { get; set; }
        public string? Phone { get; set; }
        public string? Address { get; set; }
        public int UserId { get; set; }

        public Users? Users { get; set; }
    }
}