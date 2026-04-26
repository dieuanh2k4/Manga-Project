using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Models
{
    public class Users
    {
        public int Id { get; set; }
        public string? UserName { get; set; }
        public string? Password { get; set; }
        public string? Role { get; set; }
        public int TokenVersion { get; set; } = 0;

        public Readers? Readers { get; set; }
        public Admin? Admin { get; set; }
    }
}