Central model for all accounting documents — customer invoices, vendor bills, credit notes, refunds, bank receipts, and manual/miscellaneous journal entries.
Key Functional Use Cases:

Create & post customer invoices and vendor bills
Record payments, receipts, and bank transactions
Manual journal entries and adjusting entries
Credit/debit notes and refunds
Opening/closing entries and year-end adjustments
Multi-currency, multi-company financial transactions

Technical DNA:

Model Type: models.Model (persistent + mail.thread + activity.mixin)
Key Fields:
name (char, sequenced per journal)
move_type (selection: entry, out_invoice, in_invoice, out_refund, in_refund, …)
journal_id → account.journal (required)
date, invoice_date, state (draft/posted/cancel)
partner_id, amount_untaxed, amount_tax, amount_total
currency_id, company_id, payment_state
One2many: line_ids → account.move.line (critical child)
payment_id, statement_line_id, asset_id (contextual links)

Critical Hooks: action_post, button_draft, action_reverse, _post, compute_amount, onchange_partner_id, tax & analytic computation
Security: account.group_account_manager + strong record rules by journal/company

RAG Routing Keywords:
journal entry, account move, invoice, vendor bill, customer invoice, credit note, debit note, accounting entry, posted journal, general ledger entry, move line, financial transaction, accounting document, posted move, unpaid invoice, not paid, outstanding invoice, open invoice, overdue invoice, partially paid, payment status, payment state, amount due, residual amount, awaiting payment, accounts receivable, accounts payable, invoice aging, money owed, customers owe us, who owes us, what we owe vendors, bills to pay, unpaid vendor bill, invoice status, bill status
Related Models (most joined):

account.move.line (child lines — most important)
account.journal
res.partner
account.account (via lines)
account.payment
account.bank.statement.line
account.tax

Ultra-Dense Vector Paragraph:
account.move is the main Odoo accounting document model representing journal entries, customer invoices (out_invoice), vendor bills (in_invoice), credit notes, and miscellaneous operations. It contains header data (journal_id, date, partner, totals) and links to multiple account.move.line for debit/credit details. It drives posting, reconciliation, financial reporting, and integrates with payments, bank statements, taxes, and assets.