using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace backend.src.Configurations
{
    public static class PasswordHelper
    {
        // Hash password sử dụng MD5
        public static string HashPassword(string password)
        {
            using var md5 = MD5.Create();
            var bytes = md5.ComputeHash(Encoding.UTF8.GetBytes(password));
            return BitConverter.ToString(bytes).Replace("-", "".ToLower());
        }

        // kiểm tra input passwork có khớp với hashed password không
        public static bool VerifyPassword(string inputPassword, string hashedPassword)
        {
            var hash = HashPassword(inputPassword);
            return hash.Equals(hashedPassword, StringComparison.OrdinalIgnoreCase);
        }
    }
}