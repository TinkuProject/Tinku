const test = require('node:test');
const assert = require('node:assert/strict');
const { Client } = require('pg');

const connectionString = process.env.TEST_DATABASE_URL;

async function withRollback(run) {
  const client = new Client({ connectionString });
  await client.connect();
  await client.query('BEGIN');
  try {
    await run(client);
  } finally {
    await client.query('ROLLBACK').catch(() => undefined);
    await client.end();
  }
}

async function createUser(client, suffix, role = 'user') {
  const result = await client.query(
    `INSERT INTO users (username, email, role, email_verified)
     VALUES ($1, $2, $3, true)
     RETURNING id`,
    [`integration_${suffix}`, `integration_${suffix}@tinku.test`, role]
  );
  return result.rows[0].id;
}

test(
  'marketplace settlement credits the seller exactly once',
  { skip: !connectionString },
  async () => withRollback(async (client) => {
    const suffix = `${Date.now()}_${Math.random().toString(16).slice(2)}`;
    const buyerId = await createUser(client, `${suffix}_buyer`);
    const sellerId = await createUser(client, `${suffix}_seller`, 'partner');
    await client.query(
      `INSERT INTO wallets (user_id, balance) VALUES ($1, 0), ($2, 0)`,
      [buyerId, sellerId]
    );

    const order = await client.query(
      `INSERT INTO marketplace_orders (
         buyer_id, status, payment_method, total_tinkus,
         seller_id, seller_amount_tinkus
       ) VALUES ($1, 'delivered', 'tinkus', 45, $2, 37)
       RETURNING id`,
      [buyerId, sellerId]
    );
    const orderId = order.rows[0].id;

    await client.query('SELECT * FROM settle_marketplace_order($1)', [orderId]);
    await client.query('SELECT * FROM settle_marketplace_order($1)', [orderId]);

    const wallet = await client.query(
      'SELECT balance FROM wallets WHERE user_id = $1',
      [sellerId]
    );
    const transactions = await client.query(
      `SELECT COUNT(*)::int AS total
       FROM financial_transactions
       WHERE purpose = 'marketplace_sale' AND reference_id = $1`,
      [orderId]
    );

    assert.equal(wallet.rows[0].balance, 37);
    assert.equal(transactions.rows[0].total, 1);
  })
);

test(
  'a pending Tinku charge can be reversed without seller funds',
  { skip: !connectionString },
  async () => withRollback(async (client) => {
    const suffix = `${Date.now()}_${Math.random().toString(16).slice(2)}`;
    const buyerId = await createUser(client, `${suffix}_refund`);
    await client.query(
      'INSERT INTO wallets (user_id, balance) VALUES ($1, 100)',
      [buyerId]
    );

    const spent = await client.query(
      `SELECT perform_tinku_spend($1, 30, 'marketplace_order', 999999, 'test') AS id`,
      [buyerId]
    );
    await client.query('SELECT reverse_tinku_charge($1, $2)', [
      spent.rows[0].id,
      'integration refund',
    ]);

    const wallet = await client.query(
      'SELECT balance FROM wallets WHERE user_id = $1',
      [buyerId]
    );
    const transaction = await client.query(
      'SELECT status FROM financial_transactions WHERE id = $1',
      [spent.rows[0].id]
    );

    assert.equal(wallet.rows[0].balance, 100);
    assert.equal(transaction.rows[0].status, 'reversed');
  })
);
