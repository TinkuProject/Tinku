## Requisitos
- Usuario autenticado
- Rol requerido: admin o master
- Se ejecuta de a uno.

# categories - Poblado

## POST /categories

```json
[{
  "name": "Bares",
  "entity_type": "business",
  "business_type": "business",
  "status": "active"
},
{
  "name": "Heladerías",
  "entity_type": "business",
  "business_type": "business"
},
{
  "name": "Ferias",
  "entity_type": "event"
},
{
  "name": "Cafeterías",
  "entity_type": "business",
  "business_type": "business"
},
{
  "name": "Ropa",
  "entity_type": "product"
},
{
  "name": "Educación",
  "entity_type": "business",
  "business_type": "service"
},
{
  "name": "Restaurantes",
  "entity_type": "business",
  "business_type": "business"
},
{
  "name": "Gimnasios",
  "entity_type": "business",
  "business_type": "business"
},
{
  "name": "Cines",
  "entity_type": "business",
  "business_type": "business"
},
{
  "name": "Parque",
  "entity_type": "tourist_place"
},
{
  "name": "Kermeses",
  "entity_type": "event"
},
{
  "name": "Congreso",
  "entity_type": "event"
},
{
  "name": "Tienda de Barrio",
  "entity_type": "business",
  "business_type": "business"
},
{
  "name": "Plazas",
  "entity_type": "tourist_place"
},
{
  "name": "Eventos Deportivos",
  "entity_type": "event"
},
{
  "name": "Eventos Culturales",
  "entity_type": "event"
}
]
```
---

# charging_point - Poblado

## POST /charging-points

```json
[
  {
    "name": "Correos",
    "address": "Agencia Boliviana de Correos, 313, Avenida Ayacucho, Centro Histórico, Cochabamba, Cercado, Cochabamba, Bolivia",
    "location": {
      "latitude": -17.3928763735391, 
      "longitude": -66.1585818828116
    }
  },
  {
    "name": "Terminal de Buses",
    "address": "Terminal de Buses Cochabamba, Avenida Ayacucho, San Antonio, Cochabamba, Cercado, Cochabamba, Bolivia",
    "location": {
      "latitude": -17.402619891624, 
      "longitude": -66.1575402967654
    }
  },
  {
    "name": "Univalle Tiquipaya",
    "address": "Universidad del Valle, Univalle Salida, Los Ceibos, Colcapirhua, Quillacollo, Cochabamba, Bolivia",
    "location": {
      "latitude": -17.3330014676943, 
      "longitude": -66.2263525233298
    }
  }
]
```
---

# coin_packages - Poblado

## POST /coin-packages

```json
[
  {
    "name": "basic",
    "tinkus_amount": 20,
    "cash_amount": 20
  },
  {
    "name": "silver",
    "tinkus_amount": 60,
    "cash_amount": 50
  },
  {
    "name": "gold",
    "tinkus_amount": 125,
    "cash_amount": 100
  },
  {
    "name": "premium",
    "tinkus_amount": 300,
    "cash_amount": 200
  }
]
```
---

# vehicle_types - Poblado

## POST /vehicle-types

```json
[
  {
    "name": "Minibús"
  },
  {
    "name": "Taxitrufi"
  },
  {
    "name": "Micro"
  },
  {
    "name": "Bus"
  },
  {
    "name": "Coaster"
  }
]
```
---

# transport_lines - Poblado

## POST /transport-lines

```json
[
  {
    "vehicle_type_id": 5,
    "name": "05"
  },
  {
    "vehicle_type_id": 3,
    "name": "3v"
  },
  {
    "vehicle_type_id": 1,
    "name": "120"
  },
  {
    "vehicle_type_id": 2,
    "name": "1001"
  },
  {
    "vehicle_type_id": 2,
    "name": "101 Taxi Trufi"
  },
  {
    "vehicle_type_id": 1,
    "name": "250"
  },
  {
    "vehicle_type_id": 3,
    "name": "150"
  }
]
```
---

# transport_routes - Poblado
Esta tabla cuenta con ruta de inserción masiva, ingresar el bloque de una
## POST /transport-routes/bulk

```json
[
  {
    "transport_line_id": 1,
    "direction": "outbound",
    "stop_order": 1,
    "location": {
      "latitude": -17.3877057736775,
      "longitude": -66.1597526415096
    }
  },
  {
    "transport_line_id": 1,
    "direction": "outbound",
    "stop_order": 2,
    "location": {
      "latitude": -17.3901015848321,
      "longitude": -66.159239017455
    }
  },
  {
    "transport_line_id": 1,
    "direction": "outbound",
    "stop_order": 3,
    "location": {
      "latitude": -17.3926202242672,
      "longitude": -66.158788481573
    }
  },
  {
    "transport_line_id": 1,
    "direction": "outbound",
    "stop_order": 4,
    "location": {
      "latitude": -17.3918830650952,
      "longitude": -66.154821827209
    }
  },
  {
    "transport_line_id": 1,
    "direction": "return",
    "stop_order": 1,
    "location": {
      "latitude": -17.3918830650952,
      "longitude": -66.154821827209
    }
  },
  {
    "transport_line_id": 1,
    "direction": "return",
    "stop_order": 2,
    "location": {
      "latitude": -17.3909001815782,
      "longitude": -66.1489199844443
    }
  },
  {
    "transport_line_id": 1,
    "direction": "return",
    "stop_order": 3,
    "location": {
      "latitude": -17.390459929957,
      "longitude": -66.1468489745407
    }
  }
]
[
  {
    "transport_line_id": 2,
    "direction": "outbound",
    "stop_order": 1,
    "location": {
      "latitude": -17.3862314127585,
      "longitude": -66.1600743806584
    }
  },
  {
    "transport_line_id": 2,
    "direction": "outbound",
    "stop_order": 2,
    "location": {
      "latitude": -17.3927021306584,
      "longitude": -66.1585104647214
    }
  },
  {
    "transport_line_id": 2,
    "direction": "outbound",
    "stop_order": 3,
    "location": {
      "latitude": -17.3915759145635,
      "longitude": -66.1524823106285
    }
  },
  {
    "transport_line_id": 2,
    "direction": "outbound",
    "stop_order": 4,
    "location": {
      "latitude": -17.390920658372,
      "longitude": -66.1490278017235
    }
  },
  {
    "transport_line_id": 2,
    "direction": "return",
    "stop_order": 1,
    "location": {
      "latitude": -17.3904701683789,
      "longitude": -66.1472661233534
    }
  },
  {
    "transport_line_id": 2,
    "direction": "return",
    "stop_order": 2,
    "location": {
      "latitude": -17.3920059251635,
      "longitude": -66.1556950006183
    }
  },
  {
    "transport_line_id": 2,
    "direction": "return",
    "stop_order": 3,
    "location": {
      "latitude": -17.3926775586512,
      "longitude": -66.1588730739204
    }
  }
]

```
---

# tags - Poblado

## POST /tags

```json
[
  {
    "name": "Iglesias",
    "description": "Prueba"
  },
  {
    "name": "Histórico",
    "description": "Lugares historicos"
  },
  {
    "name": "Recreativo",
    "description": "Actividades recreativas."
  },
  {
    "name": "Parque",
    "description": "Parques para la familia"
  },
  {
    "name": "Aventura",
    "description": "Aventura"
  }
  {
    "name": "Deporte",
    "description": "Deportes"
  }
]
```
---

# businesses - Poblado

## POST /businesses
Para crear negocio donde el que registra es el dueño
```json
{
  "category_id": 7,
  "name": "Chicken's Kingdom",
  "nit": "1009311029",
  "description": "Sabor y originalidad nos hacen diferentes",
  "phone": "70343229",
  "business_type": "business",
  "address": "JR6X+JWC, Cochabamba, Bolivia",
  "location": {
      "latitude": -17.3885760505884,
      "longitude": -66.1499533429742
    },
  "website": "https://chickenskingdom.com/",
}
```

## POST /businesses/system
Para crear negocios sin dueño, estos pueden ser reclamados
```json
{
    "category_id": 7,
    "name": "Tropical Chicken",
    "nit": "08898",
    "description": "",
    "phone": "",
    "business_type": "business",
    "address": "Calle Hamiraya c/c, Cochabamba, Bolivia",
    "location": {
      "latitude": -17.3932876323091,
      "longitude": -66.161626316607
    }
  }
```
---

## Notas
- business_type solo aplica cuando entity_type = "business"
- status por defecto es "active" (puede omitirse)
- No se envía id, created_at, updated_at