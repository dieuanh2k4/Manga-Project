using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Author;
using backend.src.Models;

namespace backend.src.Mappers
{
    public static class AuthorMapper
    {
        public static async Task<Authors> FromDtoToAuthor(this CreateAuthorDto dto)
        {
            return new Authors
            {
                Id = dto.Id,
                FullName = dto.FullName,
                Avatar = dto.Avatar,
                Description = dto.Description
            };
        }
    }
}