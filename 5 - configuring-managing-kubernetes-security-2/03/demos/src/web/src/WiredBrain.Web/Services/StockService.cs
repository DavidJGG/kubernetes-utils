using Microsoft.Extensions.Configuration;
using RestSharp;
using System;
using System.Threading.Tasks;
using WiredBrain.Web.Models;

namespace WiredBrain.Web.Services
{
    public class StockService
    {
        private readonly IConfiguration _config;
        private readonly DiskCache<ProductStock> _cache;
        private readonly ILogger<StockService> _logger;

        public string ApiUrl { get; private set; }

        public StockService(IConfiguration config, DiskCache<ProductStock> cache, ILogger<StockService> logger)
        {
            _config = config;
            _cache = cache;
            _logger = logger;
            ApiUrl = _config["StockApi:Url"];
        }

        public async Task<ProductStock> GetStock(long productId)
        {
            var cacheKey = $"stock_{productId}";

            // Try to get from cache first
            var cachedData = await _cache.GetAsync(cacheKey);
            if (cachedData != null)
            {
                _logger.LogDebug("Loaded stock for product {ProductId} from cache", productId);
                return cachedData;
            }

            // If not in cache, fetch from API
            _logger.LogDebug("Loading stock for product {ProductId} from API", productId);
            var client = new RestClient(ApiUrl);
            var request = new RestRequest($"{productId}");
            var response = await client.ExecuteGetAsync<ProductStock>(request);
            if (!response.IsSuccessful)
            {
                throw new Exception($"Service call failed, status: {response.StatusCode}, message: {response.ErrorMessage}");
            }

            // Save to cache
            await _cache.SetAsync(cacheKey, response.Data);

            return response.Data;
        }
    }
}
