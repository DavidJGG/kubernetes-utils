namespace WiredBrain.Web.Configuration
{
    public class CacheSettings
    {
        public bool Enabled { get; set; }

        public string CachePath { get; set; } = "/tmp/cache";
    }
}
