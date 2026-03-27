using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Dtos.Admin
{
    public class CreateAdminDto
    {
        public string? Name { get; set; }
        public string? Birth { get; set; }
        public string? Gender { get; set; }
        public string? Email { get; set; }
        public string? Avatar { get; set; }
        public string? Phone { get; set; }
        public string? Address { get; set; }
        public string? UserName { get; set; }
        public string? Password { get; set; }
    }
}