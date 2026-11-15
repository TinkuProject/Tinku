-- Asegura el paquete tecnico usado por /coin-packages/basic.
-- No se muestra en compra de monedas porque la App lo filtra por nombre.

INSERT INTO coin_packages (name, tinkus_amount, cash_amount, status)
VALUES ('partner_upgrade', 100, 20.00, 'active')
ON CONFLICT (name)
DO UPDATE SET
  tinkus_amount = EXCLUDED.tinkus_amount,
  cash_amount = EXCLUDED.cash_amount,
  status = EXCLUDED.status,
  updated_at = CURRENT_TIMESTAMP;
