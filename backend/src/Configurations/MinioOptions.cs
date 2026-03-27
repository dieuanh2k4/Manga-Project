namespace backend.src.Configurations
{
    public class MinioOptions
    {
        public const string SectionName = "Minio";

        public string Endpoint { get; set; } = string.Empty;
        public string PublicEndpoint { get; set; } = string.Empty;
        public string AccessKey { get; set; } = string.Empty;
        public string SecretKey { get; set; } = string.Empty;
        public string Bucket { get; set; } = string.Empty;
        public bool UseSSL { get; set; }
    }
}