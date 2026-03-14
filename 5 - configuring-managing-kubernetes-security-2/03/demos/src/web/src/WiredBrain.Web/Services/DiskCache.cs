using Microsoft.Extensions.Options;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using WiredBrain.Web.Configuration;

namespace WiredBrain.Web.Services
{
    public class DiskCache<T> where T : class
    {
        private readonly CacheSettings _settings;
        private readonly ILogger<DiskCache<T>> _logger;

        public DiskCache(IOptions<CacheSettings> settings, ILogger<DiskCache<T>> logger)
        {
            _settings = settings.Value;
            _logger = logger;

            if (_settings.Enabled && !Directory.Exists(_settings.CachePath))
            {
                Directory.CreateDirectory(_settings.CachePath);
                _logger.LogInformation("Created cache directory at {CachePath}", _settings.CachePath);
            }
        }

        public async Task<T?> GetAsync(string key)
        {
            if (!_settings.Enabled)
            {
                return null;
            }

            var filePath = GetCacheFilePath(key);

            if (!File.Exists(filePath))
            {
                _logger.LogDebug("Cache miss for key: {Key}", key);
                return null;
            }

            try
            {
                var json = await File.ReadAllTextAsync(filePath);
                var data = JsonSerializer.Deserialize<T>(json);
                _logger.LogDebug("Cache hit for key: {Key}", key);
                return data;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to read cache for key: {Key}", key);
                return null;
            }
        }

        public async Task SetAsync(string key, T value)
        {
            if (!_settings.Enabled)
            {
                return;
            }

            var filePath = GetCacheFilePath(key);

            try
            {
                var json = JsonSerializer.Serialize(value, new JsonSerializerOptions
                {
                    WriteIndented = true
                });
                await File.WriteAllTextAsync(filePath, json);
                _logger.LogDebug("Cached data for key: {Key}", key);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to write cache for key: {Key}", key);
            }
        }

        public void Clear(string key)
        {
            if (!_settings.Enabled)
            {
                return;
            }

            var filePath = GetCacheFilePath(key);

            if (File.Exists(filePath))
            {
                try
                {
                    File.Delete(filePath);
                    _logger.LogDebug("Cleared cache for key: {Key}", key);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to clear cache for key: {Key}", key);
                }
            }
        }

        public void ClearAll()
        {
            if (!_settings.Enabled || !Directory.Exists(_settings.CachePath))
            {
                return;
            }

            try
            {
                var files = Directory.GetFiles(_settings.CachePath, "*.json");
                foreach (var file in files)
                {
                    File.Delete(file);
                }
                _logger.LogInformation("Cleared all cache files from {CachePath}", _settings.CachePath);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to clear all cache files");
            }
        }

        private string GetCacheFilePath(string key)
        {
            var sanitizedKey = SanitizeKey(key);
            return Path.Combine(_settings.CachePath, $"{sanitizedKey}.json");
        }

        private string SanitizeKey(string key)
        {
            // Replace invalid file name characters with underscore
            var invalidChars = Path.GetInvalidFileNameChars();
            foreach (var c in invalidChars)
            {
                key = key.Replace(c, '_');
            }
            return key;
        }
    }
}
