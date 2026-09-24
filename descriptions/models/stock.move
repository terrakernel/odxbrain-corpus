Represents the atomic movement of goods (quantity of a product) from a source location to a destination location, forming the backbone of all inventory transactions.
Key Functional Use Cases:

Incoming receipts from suppliers (Purchase → Stock)
Outgoing deliveries to customers (Sales → Customer)
Internal transfers between warehouses/locations
Raw material consumption & finished goods production in Manufacturing
Stock adjustments, scrap, returns, and inventory corrections
Dropshipping, cross-docking, and transit flows
Real-time stock level updates and reservation management

Technical DNA:

Model Type: models.Model (persistent + mail.thread in some flows)
Key Fields:
name (reference), state (draft/confirmed/assigned/done/cancel)
product_id → product.product (required), product_uom_qty, quantity_done
location_id → stock.location (source), location_dest_id → stock.location (destination)
picking_id → stock.picking (parent document)
move_line_ids → One2many to stock.move.line (detailed lots/serial)
origin, reference, date, date_expected
procure_method (make_to_stock / make_to_order), priority
Computed: reserved_availability, availability, is_done

Critical Hooks: action_assign, action_done, _action_done, _prepare_move_line_vals, _update_reserved_quantity, _compute_amount
Security: stock.group_stock_user + company + location-based rules

RAG Routing Keywords:
stock move, inventory move, goods movement, stock transfer, receipt move, delivery move, internal transfer, consumption move, production move, stock.move, picking move, reserved quantity, done quantity
Related Models (most joined):

stock.picking (parent)
stock.move.line (child — lots/serial numbers)
product.product
stock.location (source & destination)
stock.quant (stock levels)
purchase.order.line / sale.order.line / mrp.production

Ultra-Dense Vector Paragraph:
stock.move is Odoo’s core inventory transaction model recording movement of product_id with quantity from location_id to location_dest_id, linked to stock.picking. It manages reservations, state transitions (confirmed → assigned → done), generates stock.quant updates, supports lots/serial tracking via move_line_ids, and integrates all flows: receipts, deliveries, internal transfers, manufacturing, and adjustments across the entire Inventory, Manufacturing, Sales and Purchase modules.