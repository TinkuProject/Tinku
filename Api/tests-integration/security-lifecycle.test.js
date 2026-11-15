const test = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');

if (!process.env.TEST_DATABASE_URL) {
  test('security lifecycle requires TEST_DATABASE_URL', { skip: true }, () => {});
} else {
  // This suite is run by test:database in its disposable local database.
  process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
  const { query, dbPool } = require('../dist/config/database.config');
  const { MarketplaceDAO } = require('../dist/dao/marketplace.dao');
  const { BoostsDAO } = require('../dist/dao/boosts.dao');
  const { MarketplaceService } = require('../dist/services/marketplace.service');
  const { AuthService } = require('../dist/services/auth.service');
  const { StripeService } = require('../dist/services/stripe.service');
  const { PgDbClient } = require('../dist/config/pg-supabase-client');
  const { WarehousesDAO } = require('../dist/dao/warehouses.dao');
  const { WarehousesService } = require('../dist/services/warehouses.service');
  const { BusinessClaimRequestsDAO } = require('../dist/dao/business-claim-requests.dao');
  const { NotificationsDAO } = require('../dist/dao/notifications.dao');
  const { NotificationsService } = require('../dist/services/notifications.service');
  const marketplace = new MarketplaceDAO();
  test.after(() => dbPool.end());

  async function user(role, balance) {
    const name = randomUUID();
    const result = await query("INSERT INTO users (username,email,role,email_verified) VALUES ($1,$2,$3,true) RETURNING *", [name, `${name}@tinku.test`, role]);
    const value = result.rows[0];
    await query('INSERT INTO wallets(user_id,balance) VALUES ($1,$2)', [value.id, balance]);
    return value;
  }

  async function fixture() {
    const buyer = await user('user', 1000);
    const seller = await user('partner', 0);
    const category = (await query("INSERT INTO categories(name,entity_type) VALUES ($1,'business') RETURNING id", [randomUUID()])).rows[0].id;
    const business = (await query(`INSERT INTO businesses(category_id,owner_id,name,business_type,address,location,validated,status)
      VALUES ($1,$2,'Test shop','business','Test address',ST_GeogFromText('POINT(-66 -17)'),true,'active') RETURNING id`, [category,seller.id])).rows[0].id;
    const product = (await query("INSERT INTO products(business_id,category_id,name,tinku_price,stock) VALUES ($1,$2,'Product',10,10) RETURNING id", [business,category])).rows[0].id;
    const publication = (await query(`INSERT INTO product_publications(product_id,business_id,created_by,published_stock,unit_tinku_price,payment_mode,status)
      VALUES ($1,$2,$3,10,10,'tinkus','active') RETURNING id`, [product,business,seller.id])).rows[0].id;
    await query('INSERT INTO business_fulfillment_options(business_id,pickup_in_store) VALUES ($1,true)', [business]);
    return { buyer, seller, category, business, product, publication,
      input: { client_request_id: randomUUID(), items: [{ publication_id: publication, quantity: 1 }], fulfillment: 'pickup', pickup_business_id: business, payment_method: 'tinkus' } };
  }

  async function balance(id) { return (await query('SELECT balance FROM wallets WHERE user_id=$1', [id])).rows[0].balance; }

  test('concurrent order retries charge and reduce stock only once', async () => {
    const f = await fixture();
    const orders = await Promise.all([marketplace.createOrder(f.buyer.id,f.input), marketplace.createOrder(f.buyer.id,f.input)]);
    assert.equal(orders[0].id,orders[1].id);
    assert.equal(await balance(f.buyer.id), 1000 - orders[0].total_tinkus);
    assert.equal((await query('SELECT published_stock FROM product_publications WHERE id=$1',[f.publication])).rows[0].published_stock,9);
    assert.equal((await query('SELECT COUNT(*)::int AS total FROM notifications WHERE entity_type=\'marketplace_order\' AND entity_id=$1',[orders[0].id])).rows[0].total,2);
    await assert.rejects(marketplace.createOrder(f.buyer.id,{...f.input,items:[{publication_id:f.publication,quantity:2}]}),/different data/);
  });

  test('only a ready, unexpired pickup settles the seller, exactly once', async () => {
    const f = await fixture();
    const order = await marketplace.createOrder(f.buyer.id,f.input);
    await assert.rejects(marketplace.validatePickupCode(order.pickup_code,{id:f.seller.id,role:'partner'}),/not ready/);
    await marketplace.updateSalesOrderStatus(order.id,f.seller.id,'preparing');
    await marketplace.updateSalesOrderStatus(order.id,f.seller.id,'ready_for_pickup');
    const service = new MarketplaceService(marketplace);
    const sales = await service.listSalesOrders(f.seller.id,undefined,20,0);
    assert.equal(sales[0].pickup_code,undefined);
    await assert.rejects(marketplace.validatePickupCode(order.pickup_code,{id:f.buyer.id,role:'user'}),/Unauthorized/);
    await marketplace.validatePickupCode(order.pickup_code,{id:f.seller.id,role:'partner'});
    await assert.rejects(marketplace.validatePickupCode(order.pickup_code,{id:f.seller.id,role:'partner'}),/already delivered/);
    assert.equal(await balance(f.seller.id),10);
    assert.equal(await marketplace.updateOrderStatus(order.id,'preparing'),null);
  });

  test('expired pickups refund the buyer and release published stock once', async () => {
    const f = await fixture();
    const order = await marketplace.createOrder(f.buyer.id,f.input);
    await query("UPDATE marketplace_orders SET status='ready_for_pickup',pickup_expires_at=now()-interval '1 second' WHERE id=$1",[order.id]);
    await assert.rejects(marketplace.validatePickupCode(order.pickup_code,{id:f.seller.id,role:'partner'}),/expired/);
    await marketplace.expirePickups();
    await marketplace.expirePickups();
    assert.equal(await balance(f.buyer.id),1000);
    assert.equal(await balance(f.seller.id),0);
    assert.equal((await query('SELECT published_stock FROM product_publications WHERE id=$1',[f.publication])).rows[0].published_stock,10);
  });

  test('refresh token rotation accepts only one concurrent use', async () => {
    const account = await user('user',0);
    const session = await AuthService.createSession(account);
    const results = await Promise.allSettled([
      AuthService.refreshToken({refresh_token:session.refresh_token}),
      AuthService.refreshToken({refresh_token:session.refresh_token}),
    ]);
    assert.equal(results.filter(result=>result.status==='fulfilled').length,1);
    assert.equal((await query('SELECT COUNT(*)::int AS total FROM user_refresh_tokens WHERE user_id=$1 AND revoked_at IS NULL',[account.id])).rows[0].total,1);
  });

  test('unprocessed webhook reservations recover after a worker restart', async () => {
    const id = randomUUID();
    await query("INSERT INTO stripe_webhook_events(id,type) VALUES ($1,'test.ignored')",[id]);
    const stripe = Object.create(StripeService.prototype);
    stripe.db = new PgDbClient({role:'master'});
    await stripe.handleWebhookEvent({id,type:'test.ignored'});
    assert.ok((await query('SELECT processed_at FROM stripe_webhook_events WHERE id=$1',[id])).rows[0].processed_at);
    assert.equal((await stripe.handleWebhookEvent({id,type:'test.ignored'})).duplicate,true);
  });

  test('boost extensions charge additional days and cannot move to another business', async () => {
    const f = await fixture();
    await query('UPDATE wallets SET balance=100 WHERE user_id=$1',[f.seller.id]);
    await query("UPDATE system_config SET value='3' WHERE key='boost_create_cost'");
    const boost = (await query("INSERT INTO boosts(entity_type,entity_id,start_date,end_date) VALUES ('business',$1,current_date,current_date+1) RETURNING *",[f.business])).rows[0];
    const dao = new BoostsDAO(new PgDbClient({userId:f.seller.id,role:'partner'}));
    const end = new Date(boost.end_date); end.setDate(end.getDate()+2);
    await dao.updateWithCharge(boost.id,{end_date:end.toISOString()},{id:f.seller.id,role:'partner'});
    assert.equal(await balance(f.seller.id),94);
    await dao.updateWithCharge(boost.id,{end_date:end.toISOString()},{id:f.seller.id,role:'partner'});
    assert.equal(await balance(f.seller.id),94);
    await assert.rejects(dao.updateWithCharge(boost.id,{entity_id:999},{id:f.seller.id,role:'partner'}),/cannot be changed/);
  });

  test('reservations reject hidden and past events and refund cancellation atomically', async () => {
    const f = await fixture();
    const event = (await query(`INSERT INTO events(creator_id,category_id,name,start_date,end_date,address,location,tinku_price,capacity,status)
      VALUES ($1,$2,'Event',now()+interval '1 day',now()+interval '2 days','Address',ST_GeogFromText('POINT(-66 -17)'),5,1,'pending') RETURNING id`,[f.seller.id,f.category])).rows[0].id;
    const context={userId:f.buyer.id,role:'user'};
    await assert.rejects(query('SELECT * FROM create_reservation_with_payment($1,$2,1)',[f.buyer.id,event],context),/not available/);
    assert.equal(await balance(f.buyer.id),1000);
    await query("UPDATE events SET status='active' WHERE id=$1",[event]);
    const reservation=(await query('SELECT * FROM create_reservation_with_payment($1,$2,1)',[f.buyer.id,event],context)).rows[0];
    assert.equal(await balance(f.buyer.id),995);
    await query('SELECT * FROM cancel_reservation_with_refund($1,$2)',[reservation.id,f.buyer.id],context);
    await query('SELECT * FROM cancel_reservation_with_refund($1,$2)',[reservation.id,f.buyer.id],context);
    assert.equal(await balance(f.buyer.id),1000);
    assert.equal(await balance(f.seller.id),0);
    await assert.rejects(query("UPDATE reservations SET status='confirmed' WHERE id=$1",[reservation.id]),/Invalid reservation transition/);
  });

  test('warehouse affiliation requires an accepted stock request', async () => {
    const f = await fixture();
    const owner = await user('partner',0);
    const warehouse = (await query("INSERT INTO warehouses(owner_id,name,validated,status) VALUES ($1,'Warehouse',true,'active') RETURNING id",[owner.id])).rows[0].id;
    const service = new WarehousesService(new WarehousesDAO());
    const input = {warehouse_delivery:true,warehouse_ids:[warehouse]};
    await assert.rejects(service.setBusinessFulfillment(f.business,input,{id:f.seller.id,role:'partner'}),/accept a stock request/);
    await query("INSERT INTO warehouse_stock_requests(business_id,warehouse_id,product_id,quantity,requested_by,status) VALUES ($1,$2,$3,1,$4,'approved')",[f.business,warehouse,f.product,f.seller.id]);
    const result = await service.setBusinessFulfillment(f.business,input,{id:f.seller.id,role:'partner'});
    assert.equal(result.warehouses.length,1);
    await assert.rejects(service.update(warehouse,{validated:true},{id:owner.id,role:'partner'}),/Forbidden/);
  });

  test('concurrent claim approvals cannot overwrite the winning owner', async () => {
    const f = await fixture();
    const other = await user('partner',0);
    const admin = await user('admin',0);
    await query('UPDATE businesses SET owner_id=NULL WHERE id=$1',[f.business]);
    const claims = (await query("INSERT INTO business_claim_requests(business_id,user_id) VALUES ($1,$2),($1,$3) RETURNING id,user_id",[f.business,f.seller.id,other.id])).rows;
    const dao = new BusinessClaimRequestsDAO(new PgDbClient({role:'master'}));
    const results = await Promise.allSettled(claims.map(claim=>dao.reviewAtomically(claim.id,admin.id,{status:'approved'})));
    assert.equal(results.filter(result=>result.status==='fulfilled').length,1);
    const approved = (await query("SELECT user_id FROM business_claim_requests WHERE business_id=$1 AND status='approved'",[f.business])).rows;
    assert.equal(approved.length,1);
    assert.equal((await query('SELECT owner_id FROM businesses WHERE id=$1',[f.business])).rows[0].owner_id,approved[0].user_id);
  });

  test('notification push failures remain queued and can be retried', async () => {
    const recipient = await user('user',0);
    const target = (await query("INSERT INTO notifications(user_id,message) VALUES ($1,'Queue test') RETURNING id",[recipient.id])).rows[0].id;
    const notifications = new NotificationsService(new NotificationsDAO(new PgDbClient({role:'master'})));
    notifications.sendPush = async notification=> { if(notification.id===target) throw new Error('simulated provider outage'); };
    await notifications.flushPushQueue();
    const queued = (await query('SELECT attempts FROM notification_push_queue WHERE notification_id=$1',[target])).rows[0];
    assert.equal(queued.attempts,1);
    await query('UPDATE notification_push_queue SET available_at=now() WHERE notification_id=$1',[target]);
    notifications.sendPush = async()=>{};
    await notifications.flushPushQueue();
    assert.equal((await query('SELECT notification_id FROM notification_push_queue WHERE notification_id=$1',[target])).rowCount,0);
  });
}
