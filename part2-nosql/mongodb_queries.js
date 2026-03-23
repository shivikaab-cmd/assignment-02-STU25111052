// ============================================================
// PART 2: MongoDB Queries
// File: part2-nosql/mongo_queries.js
// Database: retaildb   Collection: products
// Run in mongosh: load("mongo_queries.js")  OR paste in Compass Shell
// ============================================================

// Switch to working database
use("retaildb");

// ============================================================
// OP1: insertMany() — insert all 3 documents from sample_documents.json
// Bulk-inserts Electronics, Clothing, and Groceries documents.
// ordered:true ensures the operation halts on the first error.
// ============================================================
db.products.insertMany(
  [
    {
      _id: ObjectId("64a1f2c3e4b05d3a2c8f1001"),
      category: "Electronics",
      product_name: "Sony WH-1000XM5 Wireless Headphones",
      brand: "Sony",
      sku: "SNY-WH1000XM5-BLK",
      price: 29990,
      currency: "INR",
      discount_percent: 0,
      stock: {
        available: 142,
        warehouse_location: "Mumbai-WH1",
        last_restocked: "2024-02-14"
      },
      specifications: {
        driver_size_mm: 30,
        frequency_response: "4Hz–40,000Hz",
        battery_life_hours: 30,
        noise_cancellation: true,
        connectivity: ["Bluetooth 5.2", "3.5mm jack", "USB-C"],
        voltage: "5V DC",
        warranty_years: 1,
        weight_grams: 250,
        colors_available: ["Black", "Silver", "Midnight Blue"]
      },
      ratings: { average: 4.7, total_reviews: 3821 },
      tags: ["headphones", "noise-cancelling", "wireless", "premium-audio"],
      created_at: new Date("2023-09-01T10:00:00Z"),
      updated_at: new Date("2024-03-10T08:30:00Z")
    },
    {
      _id: ObjectId("64a1f2c3e4b05d3a2c8f1002"),
      category: "Clothing",
      product_name: "Levi's 511 Slim Fit Jeans",
      brand: "Levi's",
      sku: "LVS-511-32-32-IND",
      price: 2999,
      currency: "INR",
      discount_percent: 0,
      stock: {
        available: 530,
        warehouse_location: "Delhi-WH2",
        last_restocked: "2024-03-01"
      },
      specifications: {
        material: "99% Cotton, 1% Elastane",
        fit: "Slim",
        rise: "Mid-Rise",
        closure: "Zip Fly",
        care_instructions: ["Machine wash cold", "Tumble dry low", "Do not bleach"],
        sizes_available: ["28x30", "30x30", "32x32", "34x32", "36x34"],
        colors_available: ["Indigo", "Stone Wash", "Black", "Dark Navy"]
      },
      ratings: { average: 4.4, total_reviews: 6102 },
      tags: ["jeans", "slim-fit", "denim", "casual-wear"],
      created_at: new Date("2023-06-15T09:00:00Z"),
      updated_at: new Date("2024-02-28T14:15:00Z")
    },
    {
      _id: ObjectId("64a1f2c3e4b05d3a2c8f1003"),
      category: "Groceries",
      product_name: "India Gate Classic Basmati Rice 5kg",
      brand: "India Gate",
      sku: "IG-BSMTI-5KG-CLX",
      price: 649,
      currency: "INR",
      discount_percent: 0,
      stock: {
        available: 2100,
        warehouse_location: "Bengaluru-WH3",
        last_restocked: "2024-03-15"
      },
      specifications: {
        weight_kg: 5,
        grain_length: "Extra Long",
        aged_years: 2,
        organic: false,
        packaging: "Vacuum Sealed Bag",
        expiry_date: "2024-09-15",
        shelf_life_months: 18,
        allergens: ["None"],
        nutritional_info_per_100g: {
          calories_kcal: 357,
          carbohydrates_g: 78.2,
          protein_g: 7.5,
          fat_g: 0.6,
          fiber_g: 1.3
        }
      },
      ratings: { average: 4.6, total_reviews: 14350 },
      delivery: { express_available: true, estimated_days: 1, free_delivery_above: 499 },
      tags: ["rice", "basmati", "staple", "long-grain", "aged-rice"],
      created_at: new Date("2023-01-20T07:00:00Z"),
      updated_at: new Date("2024-03-16T11:00:00Z")
    }
  ],
  { ordered: true }
);
// Expected: { acknowledged: true, insertedIds: { '0': ObjectId(...), '1': ..., '2': ... } }

// ============================================================
// OP2: find() — retrieve all Electronics products with price > 20000
// Uses dot-notation not needed here; direct field query on category
// and price. Projects key display fields; suppresses _id for clarity.
// ============================================================
db.products.find(
  {
    category: "Electronics",
    price: { $gt: 20000 }
  },
  {
    _id: 0,
    product_name: 1,
    brand: 1,
    price: 1,
    "specifications.warranty_years": 1,
    "ratings.average": 1
  }
);
/*
Expected output:
{
  product_name: 'Sony WH-1000XM5 Wireless Headphones',
  brand: 'Sony',
  price: 29990,
  specifications: { warranty_years: 1 },
  ratings: { average: 4.7 }
}
*/

// ============================================================
// OP3: find() — retrieve all Groceries expiring before 2025-01-01
// Queries the nested field specifications.expiry_date using $lt.
// String comparison works here because dates are in ISO format (YYYY-MM-DD).
// In production, store expiry_date as ISODate for proper date arithmetic.
// ============================================================
db.products.find(
  {
    category: "Groceries",
    "specifications.expiry_date": { $lt: "2025-01-01" }
  },
  {
    _id: 0,
    product_name: 1,
    brand: 1,
    "specifications.expiry_date": 1,
    "stock.available": 1
  }
);
/*
Expected output:
{
  product_name: 'India Gate Classic Basmati Rice 5kg',
  brand: 'India Gate',
  specifications: { expiry_date: '2024-09-15' },
  stock: { available: 2100 }
}
*/

// ============================================================
// OP4: updateOne() — add a "discount_percent" field to a specific product
// Targets the Sony headphones by SKU; uses $set to add/update the field.
// $set is non-destructive — it only touches the specified field,
// leaving all other document fields intact.
// ============================================================
db.products.updateOne(
  { sku: "SNY-WH1000XM5-BLK" },
  {
    $set: {
      discount_percent: 10,
      updated_at: new Date()
    }
  }
);
/*
Expected output:
{ acknowledged: true, matchedCount: 1, modifiedCount: 1, upsertedId: null }

Verify with:
db.products.findOne({ sku: "SNY-WH1000XM5-BLK" }, { product_name: 1, price: 1, discount_percent: 1 })
*/

// ============================================================
// OP5: createIndex() — create an index on the category field
// An index on "category" dramatically speeds up all queries that
// filter by product category (the most common access pattern in a
// product catalogue). Without this index, every find({ category: "..." })
// performs a full collection scan (COLLSCAN), which is O(n).
// With the index, MongoDB uses IXSCAN, reducing lookup to O(log n).
// As the collection grows to millions of products, this difference
// becomes critical for API response times.
// ============================================================
db.products.createIndex(
  { category: 1 },
  {
    name: "idx_category_asc",
    background: true   // non-blocking build (implicit in MongoDB 4.2+)
  }
);
/*
Expected output: 'idx_category_asc'

Verify index usage:
db.products.explain("executionStats").find({ category: "Electronics" })
Look for: winningPlan.stage === "IXSCAN"  (not "COLLSCAN")

List all indexes:
db.products.getIndexes()
*/
