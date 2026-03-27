using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Dtos.Auth
{
    public class AuthResultDto
    {
        public bool IsSuccess { get; set; }
        public string? Message { get; set; }
        public LoginResponseDto? Data { get; set; }

        public static AuthResultDto Success(LoginResponseDto data, string? message = null)
        {
            return new AuthResultDto
            {
                IsSuccess = true,
                Data = data,
                Message = message
            };
        }

        public static AuthResultDto Fail(string message)
        {
            return new AuthResultDto
            {
                IsSuccess = false,
                Message = message
            };
        }
    }
}