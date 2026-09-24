Allows flexible, cross-cutting classification and labeling of products (and variants) beyond the hierarchical product.category, for filtering, reporting, promotions, and search.
Key Functional Use Cases:

Quick filtering and grouping of products in sales, purchase, inventory, and POS
Marketing & promotions (apply discounts/loyalty to tagged products)
Internal organization (seasonal, best-seller, clearance, hazardous, etc.)
Website/eCommerce faceted search and product listing
Mass updates and reporting by tag
Restaurant/POS item grouping (e.g., “Spicy”, “Vegan”)

Technical DNA:

Model Type: models.Model (persistent, lightweight)
Key Fields:
name (char, required), color (integer for tag color)
active (boolean)
company_id (optional)

Relations:
Many2many on product.template: tag_ids (or product_tag_ids)
Many2many on product.product: tag_ids

Critical Hooks: Simple create/write, used in domain filters and search views
Security: Usually open to product users (product.group_product_user)

RAG Routing Keywords:
product tag, product tags, item tag, product.label, tagged product, product classification, tag filter, product grouping, promotional tag, clearance tag, seasonal tag, pos tag, product_tag_ids
Related Models (most joined):

product.template (via tag_ids)
product.product (via tag_ids)
product.category (complementary)
sale.order.line, pos.order.line, purchase.order.line (filter by tag)
Loyalty / Promotion rules (product_tag domain)

Ultra-Dense Vector Paragraph:
product.tag is Odoo’s lightweight tagging model for products, storing name and color, linked via Many2many (tag_ids) to product.template and product.product. It enables flexible non-hierarchical classification, advanced filtering, promotions, reporting, POS grouping, and website search, complementing the rigid product.category structure across Sales, Inventory, Manufacturing, and eCommerce.