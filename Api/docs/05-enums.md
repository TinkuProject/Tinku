# Enums

Este documento refleja los enums definidos en `database/01-db.sql` y usados en `src/constants/enums.constants.ts`.

Regla: si cambia un enum en DB, actualizar también constantes, validaciones Zod, DTOs y este documento.

## Usuarios

### user_role

- `user`
- `partner`
- `admin`
- `master`

### user_status

- `active`
- `inactive`
- `suspended`
- `deleted`

## Economía

### transaction_type

- `purchase`
- `spend`
- `reward`
- `refund`
- `cashout`
- `admin_adjustment`

### transaction_status

- `pending`
- `approved`
- `rejected`
- `failed`
- `cancelled`
- `reversed`

### payment_method

- `qr`
- `gateway`
- `cash_point`

### payment_status

- `pending`
- `approved`
- `rejected`
- `failed`
- `cancelled`
- `expired`

### payment_type

- `partner_upgrade`
- `coin_purchase`
- `subscription`
- `product_publication`

### approval_status

- `pending`
- `approved`
- `rejected`

## Negocios Y Contenido

### business_type

- `business`
- `service`

### business_status

- `active`
- `inactive`
- `suspended`
- `pending`

### product_status

- `active`
- `inactive`
- `out_of_stock`

### warehouse_status

- `pending`
- `active`
- `inactive`
- `archived`

### warehouse_inventory_status

- `available`
- `reserved`
- `delivered`
- `returned`
- `cancelled`

### marketplace_publication_status

- `draft`
- `active`
- `paused`
- `sold_out`
- `archived`

### marketplace_order_status

- `pending`
- `paid`
- `preparing`
- `ready_for_pickup`
- `in_delivery`
- `delivered`
- `cancelled`

### delivery_status

- `pending`
- `assigned`
- `picked_up`
- `delivered`
- `cancelled`

### fulfillment_method

- `pickup`
- `warehouse_delivery`

### event_status

- `pending`
- `active`
- `finished`
- `cancelled`

### promotion_status

- `active`
- `inactive`
- `cancelled`

### category_entity_type

- `business`
- `event`
- `tourist_place`
- `product`

### update_entity_type

- `business`
- `event`
- `product`
- `certification`

## Interacción

### visit_type

- `visited`
- `favorited`

### reservation_status

- `pending`
- `confirmed`
- `cancelled`

### event_ticket_status

- `active`
- `used`
- `expired`
- `cancelled`

Uso:

- `active`: ticket o ticket-día emitido y disponible.
- `used`: ticket-día ya escaneado.
- `expired`: ticket-día fuera de su ventana de validez.
- `cancelled`: ticket cancelado por cancelación de reserva/evento.

### review_status

- `visible`
- `hidden`
- `reported`

### visit_entity

- `tourist_place`
- `business`
- `event`

### review_entity_type

- `tourist_place`
- `business`
- `event`
- `product`

## Media

### media_type

- `image`
- `video`
- `file`

### media_entity_type

- `business`
- `event`
- `tourist_place`
- `product`
- `user`
- `review`
- `certification`
- `category`
- `payment`
- `coin_package`
- `subscription`
- `discount`
- `transport_line`
- `charging_point`
- `warehouse`
- `product_publication`

Nota: `charging_point` fue agregado al SQL versionado para alinearlo con las constantes del backend.

## Transporte

### route_direction

- `outbound`
- `return`

## Suscripciones

### subscription_status

- `active`
- `paused`
- `cancelled`
- `expired`

## General

### basic_status

- `active`
- `inactive`
- `archived`

Uso: categorías, tags, tourist places, paquetes, certificaciones y otras entidades simples.

### charging_point_status

- `active`
- `inactive`
- `maintenance`

### opening_entity

- `business`
- `event`
- `tourist_place`
- `charging_point`

### week_day

- `monday`
- `tuesday`
- `wednesday`
- `thursday`
- `friday`
- `saturday`
- `sunday`

## Reglas De Mantenimiento

1. No usar strings libres para estados críticos.
2. No crear enums duplicados si el significado es idéntico.
3. No reutilizar enums si el significado de negocio cambia.
4. Revisar migrations/RLS/RPC antes de cambiar valores existentes.
5. Si se agrega un valor, actualizar Postman, validaciones y documentación de flujos.
