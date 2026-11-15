const test = require('node:test');
const assert = require('node:assert/strict');

const { MarketplaceService } = require('../dist/services/marketplace.service.js');

test('partner can reject only through the ownership-scoped path', async () => {
  const calls = [];
  const dao = {
    rejectOrderBySeller: async (...args) => {
      calls.push(args);
      return { id: 8, buyer_id: 'buyer-1' };
    },
  };
  const notifications = { createSafely: async () => ({}) };
  const service = new MarketplaceService(dao, notifications);

  await service.rejectSalesOrder(8, 'El producto ya no está disponible.', {
    id: 'partner-1',
    role: 'partner',
  });

  assert.deepEqual(calls, [
    [8, 'partner-1', 'El producto ya no está disponible.', false],
  ]);
});

test('admin rejection explicitly bypasses seller ownership', async () => {
  const calls = [];
  const dao = {
    rejectOrderBySeller: async (...args) => {
      calls.push(args);
      return { id: 9, buyer_id: 'buyer-2' };
    },
  };
  const notifications = { createSafely: async () => ({}) };
  const service = new MarketplaceService(dao, notifications);

  await service.rejectSalesOrder(9, 'Cancelación administrativa justificada.', {
    id: 'admin-1',
    role: 'admin',
  });

  assert.deepEqual(calls, [
    [9, 'admin-1', 'Cancelación administrativa justificada.', true],
  ]);
});
