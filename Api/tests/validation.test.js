const test = require('node:test');
const assert = require('node:assert/strict');

const {
  marketplaceOrderCreateSchema,
  marketplaceOrderRejectionSchema,
} = require('../dist/validation/marketplace.validation.js');
const {
  notificationCreateSchema,
} = require('../dist/validation/notifications.validation.js');

const baseOrder = {
  client_request_id: '00000000-0000-4000-8000-000000000001',
  items: [{ publication_id: 1, quantity: 1 }],
  fulfillment: 'pickup',
  pickup_business_id: 2,
};

test('marketplace accepts Tinkus and rejects obsolete Stripe payments', () => {
  assert.equal(
    marketplaceOrderCreateSchema.parse({ ...baseOrder }).payment_method,
    'tinkus'
  );
  assert.equal(
    marketplaceOrderCreateSchema.safeParse({
      ...baseOrder,
      payment_method: 'stripe',
    }).success,
    false
  );
});

test('marketplace seller rejection requires a meaningful reason', () => {
  assert.equal(
    marketplaceOrderRejectionSchema.safeParse({ reason: 'sin stock' }).success,
    false
  );
  assert.equal(
    marketplaceOrderRejectionSchema.safeParse({
      reason: 'El producto sufrió un daño y no puede entregarse.',
    }).success,
    true
  );
});

test('structured notification accepts a safe internal route', () => {
  const parsed = notificationCreateSchema.parse({
    user_id: 'c949a797-b724-445d-99f3-1d177ca246bd',
    message: 'Pedido actualizado',
    type: 'marketplace_order',
    entity_type: 'marketplace_order',
    entity_id: 7,
    route: '/myMarketplaceOrders',
  });

  assert.equal(parsed.route, '/myMarketplaceOrders');
  assert.equal(parsed.entity_id, 7);
});

test('structured notification rejects external URLs', () => {
  const result = notificationCreateSchema.safeParse({
    user_id: 'c949a797-b724-445d-99f3-1d177ca246bd',
    message: 'Abrir enlace',
    route: 'https://example.com',
  });

  assert.equal(result.success, false);
});
