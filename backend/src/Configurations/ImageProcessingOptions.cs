namespace backend.src.Configurations
{
    public class ImageProcessingOptions
    {
        public const string SectionName = "ImageProcessing";

        public int ResizeWidth { get; set; } = 1280;
        public int ResizeHeight { get; set; } = 1280;
        public int WebpQuality { get; set; } = 75;
        public string? TempDirectory { get; set; }
    }
}
