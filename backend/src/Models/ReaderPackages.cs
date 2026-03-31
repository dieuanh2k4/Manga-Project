using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Models
{
    public class ReaderPackages
    {
        public int Id { get; set; }
        public int ReaderId { get; set; }
        public int PackageId { get; set; }
        public DateTime PurchasedAt { get; set; } = DateTime.UtcNow;
        public DateTime? ExpiredAt { get; set; }

        public Readers? Reader { get; set; }
        public Packages? Package { get; set; }
    }
}
