-- Agrega el tipo de pago para ordenes de marketplace.
-- PostgreSQL exige commitear el nuevo valor del enum antes de usarlo en constraints.

ALTER TYPE payment_type ADD VALUE IF NOT EXISTS 'marketplace_order';
