# 1 набор Бд шаблонов

// Пользователь
table user {
  id SERIAL [NOT NULL, PK]
  role_id INT [ref: >?]
  username VARCHAR(50) [NOT NULL, unique]
  user_email VARCHAR(60) [NOT NULL, unique]
  user_password TEXT [NOT NULL]
  created_at timestamptz(CURRENT_TIMESTAMPTZ)
}

// Роли - Покупатель, поддержка, админ
table roles {
  id SERIAL [NOT NULL, PK]
  name VARCHAR(50) [NOT NULL, unique]
}

// Приложения
table application {
  id SERIAL [not null, PK]
  title VARCHAR(100) [NOT NULL]
  image_url VARCHAR(100)
  created_at timestamptz(CURRENT_TIMESTAMPTZ)
}

// Ключи
table key {
  id SERIAL [NOT NULL, PK]
  key_kode VARCHAR(50) [NOT NULL, unique]
  key_duration INT [NOT NULL]
  key_state BOOLEAN(false) [NOT NULL]
  activated_at timestamptz
  expires_at timestamptz
  created_by INT [ref: >? user.id]
  application_id INT [ref: >? application.id]
}

// Заказы
table order {
  id SERIAL [NOT NULL, PK]
  user_id INT [ref: >? user.id]
  status VARCHAR(30)
  total_amount DECIMAL(5,0) [NOT NULL]
  payment_method VARCHAR(30) [NOT NULL]
  created_at timestamptz(CURRENT_TIMESTAMPTZ)
}

// Купленные ключи
table order_keys {  
  id SERIAL [NOT NULL, PK]
  user_id INT [ref: >? user.id]
  order_id INT [ref: >? order.id]
  key_id INT [ref: >? key.id]
  duration_days INT [NOT NULL]
  purchase_date timestamptz(CURRENT_TIMESTAMPTZ)
}

// ключи пользователей
table user_key {
  id SERIAL [NOT NULL, PK]
  user_id INT [ref: ?>? user.id]
  key_id INT [ref: >? key.id]
  application INT [ref: >? application.id]
  hwid_key VARCHAR(100)
  activation_date timestamptz()
  end_date timestamptz
}

 
#  2 надор шаблонов

// Пользователи
Table users {
  id serial [pk]
  role_id int [not null, ref: > roles.id]

  username varchar(50) [not null, unique]
  email varchar(255) [not null, unique]
  password_hash text [not null]

  is_active boolean [not null, default: true]

  created_at timestamptz [not null, default: `now()`]
  updated_at timestamptz
}


// Роли
Table roles {
  id serial [pk]
  name varchar(50) [not null, unique]
}


// Программные продукты
Table applications {
  id serial [pk]

  title varchar(100) [not null]
  description text
  image_url text

  price decimal(10,2) [not null]

  is_active boolean [not null, default: true]

  created_at timestamptz [not null, default: `now()`]
  updated_at timestamptz
}


// Ключи активации
Table keys {
  id serial [pk]

  key_code varchar(255) [not null, unique]

  application_id int [not null, ref: > applications.id]

  duration_days int [not null]

  status varchar(30) [not null]

  created_by int [ref: >? users.id]

  created_at timestamptz [not null, default: `now()`]
}


// Заказы
Table orders {
  id serial [pk]

  user_id int [not null, ref: > users.id]

  status varchar(30) [not null]

  total_amount decimal(10,2) [not null]

  payment_method varchar(30)

  created_at timestamptz [not null, default: `now()`]
}


// Состав заказа
Table order_items {
  id serial [pk]

  order_id int [not null, ref: > orders.id]
  key_id int [not null, ref: > keys.id]

  price decimal(10,2) [not null]
  duration_days int [not null]

  created_at timestamptz [not null, default: `now()`]
}


// Активации
Table activations {
  id serial [pk]

  key_id int [not null, ref: > keys.id]
  user_id int [not null, ref: > users.id]
  application_id int [not null, ref: > applications.id]

  hwid varchar(255) [not null]

  activated_at timestamptz [not null, default: `now()`]
  expires_at timestamptz

  deactivated_at timestamptz
}


# 1 пробная таблци пользователей с ролями

 // Таблица пользователей
Table users {
  id serial [pk]
  role_id int [not null, ref: > roles.id]

  username varchar(50) [not null, unique]
  email varchar(255) [not null, unique]
  password_hash text [not null]

  created_at timestamptz [not null, default: `now()`]
}

// Таблица ролей, покупатель, поддержка, админ
Table roles {
  id serial [pk]
  name varchar(50) [NOT NULL, unique]
}

// Соединяет роли и правила для них
Table role_permissions {
  role_id int [NOT NULL, ref: > roles.id]
  permission_id int [NOT NULL, ref: > permissions.id]

  indexes {
    (role_id, permission_id) [pk]
  }
}

// Права для ролей
Table permissions {
  id serial [pk]
  name varchar(100) [NOT NULL, unique]
}
