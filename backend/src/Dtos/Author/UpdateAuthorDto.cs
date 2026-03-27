using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace backend.src.Dtos.Author
{
    public class UpdateAuthorDto
    {
        public string? FullName { get; set; }
        public string? Avatar { get; set; }
        public IFormFile? AvatarFile { get; set; }
        public string? Description { get; set; }
    }
}