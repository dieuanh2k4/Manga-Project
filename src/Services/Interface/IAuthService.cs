using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Auth;
using backend.src.Models;

namespace backend.src.Services.Interface
{
    public interface IAuthService
    {
        Task<AuthResultDto> Login(LoginRequestDto request);
        Task<Users> Register(RegisterDto register);
    }
}