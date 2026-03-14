using Microsoft.Extensions.Configuration;
using RestSharp;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using WiredBrain.Web.Models;

namespace WiredBrain.Web.Services
{
    public class ProductService
    {
        private readonly IConfiguration _config;
        private readonly DiskCache<IEnumerable<Product>> _cache;
        private readonly ILogger<ProductService> _logger;
        private const string CacheKey = "products_all";

        public string ApiUrl { get; private set; }

        public ProductService(IConfiguration config, DiskCache<IEnumerable<Product>> cache, ILogger<ProductService> logger)
        {
            _config = config;
            _cache = cache;
            _logger = logger;
            ApiUrl = _config["ProductsApi:Url"];
        }

        public async Task<IEnumerable<Product>> GetProducts()
        {
            // Try to get from cache first
            var cachedData = await _cache.GetAsync(CacheKey);
            if (cachedData != null)
            {
                _logger.LogDebug("Loaded products from cache");
                return cachedData;
            }

            // If not in cache, fetch from API
            _logger.LogDebug("Loading products from API");
            var client = new RestClient(ApiUrl);
            var request = new RestRequest();
            var response = await client.ExecuteGetAsync<IEnumerable<Product>>(request);
            if (!response.IsSuccessful)
            {
                throw new Exception($"Service call failed, status: {response.StatusCode}, message: {response.ErrorMessage}");
            }

            // Save to cache
            await _cache.SetAsync(CacheKey, response.Data);

            return response.Data;
        }
    }
}
