using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Minio;

namespace backend.src.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Policy = "AdminOnly")]
    public class AdminController : ApiControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IMinioClient _minio;
        private readonly IAdminService _admin;

        public AdminController(ApplicationDbContext context, IAdminService admin, IMinioClient minio, ILogger<AdminController> logger) : base(logger)
        {
            _context = context;
            _admin = admin;
            _minio = minio;
        }
    }
}