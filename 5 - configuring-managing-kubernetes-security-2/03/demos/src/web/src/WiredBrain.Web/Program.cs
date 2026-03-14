using Prometheus;
using WiredBrain.Web.Configuration;
using WiredBrain.Web.Models;
using WiredBrain.Web.Services;

namespace WiredBrain.Web;

public class Program
{
    private static readonly Gauge _InfoGauge = 
        Metrics.CreateGauge("app_info", "Application info", "dotnet_version", "assembly_name", "app_version");

    public static void Main(string[] args)
    {
        _InfoGauge.Labels("8.0", "WiredBrain.Web", "0.4.0").Set(1);
        
        var builder = WebApplication.CreateBuilder(args);
        
        // Add configuration sources
        builder.Configuration
            .AddJsonFile("appsettings.json")
            .AddEnvironmentVariables()
            .AddJsonFile("config/logging.json", optional: true, reloadOnChange: true)
            .AddJsonFile("secrets/api.json", optional: true, reloadOnChange: true)
            .AddJsonFile("/run/secrets/api.json", optional: true, reloadOnChange: true);

        // Add services to the container
        builder.Services.AddControllersWithViews();

        // Configure cache settings
        builder.Services.Configure<CacheSettings>(builder.Configuration.GetSection("Cache"));

        // Register cache services
        builder.Services.AddSingleton(typeof(DiskCache<>));

        builder.Services.AddScoped<ProductService>();
        builder.Services.AddScoped<StockService>();

        var app = builder.Build();

        // Configure the HTTP request pipeline
        if (!app.Environment.IsDevelopment())
        {
            app.UseExceptionHandler("/Error");
        }
        else
        {
            app.UseDeveloperExceptionPage();
        }

        app.UseStaticFiles();
        app.UseRouting();
        
        app.UseMetricServer();
        app.UseHttpMetrics();
        
        app.UseAuthorization();
        
        app.MapControllerRoute(
            name: "default",
            pattern: "{controller=Home}/{action=Index}/{id?}");

        app.Run();
    }
}
