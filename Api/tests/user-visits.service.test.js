const test = require('node:test');
const assert = require('node:assert/strict');

const { UserVisitsService } = require('../dist/services/user-visits.service.js');

test('getByEntity scopes visits to the authenticated user', async () => {
  const calls = [];
  const dao = {
    findByEntity: async (...args) => {
      calls.push(args);
      return [];
    },
  };
  const service = new UserVisitsService(dao);
  const input = { entity_type: 'business', entity_id: 12 };

  await service.getByEntity('user-1', input);

  assert.deepEqual(calls, [['user-1', input]]);
});

test('favorite creation rejects duplicates for the same user and entity', async () => {
  let created = false;
  const dao = {
    exists: async () => true,
    create: async () => {
      created = true;
      return {};
    },
  };
  const service = new UserVisitsService(dao);

  await assert.rejects(
    service.create('user-1', {
      entity_type: 'business',
      entity_id: 12,
      type: 'favorited',
    }),
    /already exists/
  );
  assert.equal(created, false);
});
