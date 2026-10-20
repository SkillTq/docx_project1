
// 1. Роли и пользователи
Table roles {
  id serial [pk]
  name varchar(50) [not null, unique]
}

Table permissions {
  id serial [pk]
  name varchar(100) [not null, unique]
}

Table role_permissions {
  role_id int [not null, ref: > roles.id]
  permission_id int [not null, ref: > permissions.id]

  indexes {
    (role_id, permission_id) [pk]
  }
}

Table users {
  id uuid [pk, default: `gen_random_uuid()`]

  role_id int [not null, ref: > roles.id]

  username varchar(50) [not null, unique]
  email varchar(255) [unique]
  password_hash text [not null]

  created_at timestamptz [not null, default: `now()`]
}

// 2. ПРИЛОЖЕНИЯ И ТАРИФЫ
Table applications {
  id serial [pk]

  title varchar(100) [not null]
  description text
  image_url text

  is_active boolean [not null, default: true]

  created_by_user_id uuid [ref: > users.id]

  created_at timestamptz [not null, default: `now()`]
  updated_at timestamptz
}

Table application_plans {
  id serial [pk]

  application_id int [not null, ref: > applications.id]

  name varchar(100) [not null]
  duration_days int [not null]
  price decimal(10,2) [not null]

  is_active boolean [not null, default: true]

  created_at timestamptz [not null, default: `now()`]
  updated_at timestamptz

  indexes {
    (application_id, duration_days) [unique]
  }

  checks {
    `duration_days > 0`
    `price >= 0`
  }
}

// 3. СКЛАД КЛЮЧЕЙ

Table keys {
  id serial [pk]

  key_code varchar(255) [not null, unique]

  plan_id int [not null, ref: > application_plans.id]

  status varchar(30) [not null, default: 'available']

  created_by_user_id uuid [ref: > users.id]

  created_at timestamptz [not null, default: `now()`]

  indexes {
    (plan_id, status)
  }

  checks {
    `status IN ('available', 'reserved', 'sold', 'revoked')`
  }
}

// 4. ЗАКАЗЫ И ИХ СОСТАВ
Table orders {
  id serial [pk]

  user_id uuid [not null, ref: > users.id]

  status varchar(30) [not null, default: 'pending_payment']
  total_amount decimal(10,2) [not null]

  created_at timestamptz [not null, default: `now()`]
  updated_at timestamptz

  indexes {
    (user_id, created_at)
    (status, created_at)
  }

  checks {
    `total_amount >= 0`
    `status IN ('pending_payment', 'paid', 'processing', 'completed', 'cancelled', 'refunded')`
  }
}

Table order_items {
  id serial [pk]

  order_id int [not null, ref: > orders.id]

  plan_id int [not null, ref: > application_plans.id]

  // NULL до выдачи ключа
  key_id int [unique, ref: > keys.id]

  // Снимок условий на момент покупки
  plan_name varchar(100) [not null]
  duration_days int [not null]
  price decimal(10,2) [not null]

  created_at timestamptz [not null, default: `now()`]

  indexes {
    (order_id)
  }

  checks {
    `duration_days > 0`
    `price >= 0`
  }
}

// 5. ПЛАТЕЖИ
Table payments {
  id serial [pk]

  order_id int [not null, ref: > orders.id]

  provider varchar(50) [not null]
  provider_payment_id varchar(255) [unique]

  amount decimal(10,2) [not null]
  status varchar(30) [not null, default: 'pending']

  created_at timestamptz [not null, default: `now()`]
  paid_at timestamptz

  indexes {
    (order_id, created_at)
  }

  checks {
    `amount >= 0`
    `status IN ('pending', 'succeeded', 'failed', 'refunded')`
  }
}

// 6. АКТИВАЦИИ
Table activations {
  id serial [pk]

  key_id int [not null, ref: > keys.id]
  user_id uuid [not null, ref: > users.id]

  hwid varchar(255) [not null]

  activated_at timestamptz [not null, default: `now()`]
  expires_at timestamptz [not null]

  deactivated_at timestamptz

  indexes {
    (user_id, activated_at)
    (key_id, activated_at)
  }

  checks {
    `expires_at > activated_at`
    `deactivated_at IS NULL OR deactivated_at >= activated_at`
  }
}
