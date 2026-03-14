using System.Collections.Generic;

namespace WiredBrain.Web.Models
{
    public class ProductViewModel
    {
        public IEnumerable<Product> Products { get; set; }
        public string ErrorMessage { get; set; }
    }
}
