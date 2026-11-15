const test = require('node:test');
const assert = require('node:assert/strict');
const { PaymentRequestService } = require('../dist/services/payment-requests.service');
const { StripeService } = require('../dist/services/stripe.service');
const { WarehousesService } = require('../dist/services/warehouses.service');
const { UsersService } = require('../dist/services/users.service');
const { EntityUpdatesService } = require('../dist/services/entity-updates.service');
const { StorageService } = require('../dist/services/storage.service');
const { withoutPickupSecret } = require('../dist/services/marketplace.service');

test('manual requests cannot replace a gateway purchase target', async () => {
  let created = false;
  const service = new PaymentRequestService({ create: async () => { created = true; } },
    { findById: async () => ({ id: 1, method: 'gateway', user_id: 'buyer', type: 'coin_purchase', status: 'pending' }) });
  await assert.rejects(service.create('buyer', { paymentId: 1, type: 'coin_purchase', targetId: 999 }), /processed by Stripe/);
  assert.equal(created, false);
});

test('Stripe rejects changed amounts, currency, user, and target', async () => {
  const service = Object.create(StripeService.prototype);
  const payment = { id: 1, user_id: 'buyer', amount: 20, amount_minor: 2000, currency: 'BOB',
    method: 'gateway', type: 'coin_purchase', gateway_target_id: 2 };
  const intent = { status: 'succeeded', amount: 2000, amount_received: 2000, currency: 'bob',
    metadata: { payment_id: '1', user_id: 'buyer', type: 'coin_purchase', target_id: '2' } };
  service.assertIntentBinding(payment, intent);
  for (const change of [{ amount: 1 }, { currency: 'usd' }, { amount_received: 1 },
    { metadata: { ...intent.metadata, target_id: '99' } }, { metadata: { ...intent.metadata, user_id: 'someone' } }]) {
    assert.throws(() => service.assertIntentBinding(payment, { ...intent, ...change }), /mismatch/);
  }
  service.paymentsDao = { findByExternalReference: async () => payment };
  service.paymentRequestsDao = { findByPaymentId: async () => ({ id: 3, userId: 'buyer', type: 'coin_purchase', targetId: 999 }) };
  await assert.rejects(service.approvePaymentIntent(intent), /mismatch/);
});

test('partners cannot approve or transfer their warehouse through editing', async () => {
  let updated = false;
  const service = new WarehousesService({ update: async () => { updated = true; } });
  service.assertWarehouseAccess = async () => {};
  for (const data of [{ status: 'active' }, { validated: true }, { owner_id: 'someone' }]) {
    await assert.rejects(service.update(1, data, { id: 'owner', role: 'partner' }), /Forbidden/);
  }
  assert.equal(updated, false);
});

test('profile editing cannot bypass new-email verification', async () => {
  const service = new UsersService({ findById: async () => ({ email: 'old@example.test' }), update: async input => input });
  await assert.rejects(service.update({ id: 'user', email: 'new@example.test' }), /require verification/);
  assert.equal((await service.update({ id: 'user', email: 'old@example.test' })).email, 'old@example.test');
});

test('seller responses do not contain pickup or idempotency secrets', () => {
  assert.deepEqual(withoutPickupSecret({ id: 4, pickup_code: 'secret', client_request_id: 'key', request_hash: 'hash' }), { id: 4 });
});

test('media cannot refer to a different bucket or another entity', () => {
  assert.throws(() => StorageService.extractFilePath('https://attacker.test/bucket/file.webp'));
  const url = StorageService.buildPublicUrl('business/8/photo.webp');
  assert.throws(() => StorageService.assertEntityFile(url, 'business', 9), /Forbidden/);
  assert.equal(StorageService.assertEntityFile(url, 'business', 8), 'business/8/photo.webp');
});

test('replaying rejection cannot delete files from an already reviewed update', async () => {
  let deleted = false;
  const service = new EntityUpdatesService({ findById: async () => ({ id: 1, status: 'approved' }) });
  service.cleanupAddedMediaFiles = async () => { deleted = true; };
  await assert.rejects(service.reject({ update_id: 1 }, { id: 'admin', role: 'admin' }), /already reviewed/);
  assert.equal(deleted, false);
});
