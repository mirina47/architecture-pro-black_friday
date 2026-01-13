# Задание 7. Проектирование схем коллекций для шардирования данных

## Схемы коллекций

### Коллекция orders
```
_id: Integer
client_id: Integer
created_at: Timestamp
items: Array[
    name: String
    price: Decimal128
]
status: String
total_amount: Decimal128
geozone: GeoJSON
```

### Коллекция products
```
_id: Integer
title: String
category: String
price: Decimal128
stock: {
    zone_id: Integer
    quantity: Decimal128
    updated_at: Timestamp
}
attr: {
   color: String
   size: Decimal128
}
```

### Коллекция carts
```
_id: Integer
user_id: Integer 
session_id: Integer
client_id: Integer // user_id или session_id
created_at: Timestamp
items: Array[
    product_id: Integer
    quantity: Decimal128
]
status: String enum ["active", "ordered", "abandoned"]
created_at: Timestamp
updated_at: Timestamp
expires_at: Timestamp
```

## Стратегии шардирования

### Коллекция orders
**Шард-ключ**: ```{ client_id: 1, _id: 1 }```

**Стратегия**: Диапазонное шардирование

**Обоснование**:
- Ключ client_id обеспечивает быструю работу таких запросов, как поиск истории заказов конкретного клиента. Добавление _id помогает равномерно распределить заказы очень активных клиентов.
- Диапазонное шардирование подходит, так как заказы относятся к последовательным данным. Также в плюсах легкая реализуемость и быстрый поиск информации по сравнению с хэшированием.

**Пример команды**: 
```
sh.shardCollection("db.orders", { client_id: 1, _id: 1 })
```

### Коллекция products
**Шард-ключ**: ```{ "_id" : "hashed" }```

**Стратегия**: Хэшированное шардирование

**Обоснование**:
- Ключ _id уникален, поэтому может обеспечить хорошее распределение данных
- Хэшированное шардирование подходит, так как товары в магазине крайне важно распределять равномерно. Также в плюсах высокая производительность и отсутствие единой точки отказа.

**Пример команды**: 
```
sh.shardCollection("db.products", { "_id" : "hashed" })
```

### Коллекция carts
**Шард-ключ**: ```{ "client_id" : "hashed" }```

**Стратегия**: Хэшированное шардирование

**Обоснование**:
- Ключ client_id обеспечивает быстрый доступ для операций добавления/удаления товаров в корзине.
- Хэшированное шардирование подходит, так как нагрузка распределена равномерно, что крайне важно в период акций. Также в плюсах высокая производительность и отсутствие единой точки отказа.

**Пример команды**: 
```
sh.shardCollection("db.carts", { "client_id" : "hashed" })
```