// Таблица пользователей
Table users {
  id uuid [pk, default: `gen_random_uuid()`]
  role_id uuid [not null, ref: > roles.id]

  username varchar(50) [not null, unique]
  email varchar(100) [unique]
  password_hash text [not null]

  created_at timestamptz [not null, default: `now()`]
}

// Таблица ролей, покупатель, поддержка, админ
Table roles {
  id uuid [pk, default: `gen_random_uuid()`]
  name varchar(50) [not null, unique]
}

// Соединяет роли и права для ролей
Table role_permissions {
  role_id uuid [not null, ref: > roles.id]
  permission_id uuid [not null, ref: > permissions.id]

  indexes {
    (role_id, permission_id) [pk]
  }
}

// Права для ролей
Table permissions {
  id uuid [pk, default: `gen_random_uuid()`]
  name varchar(100) [NOT NULL, unique]
}


// Приложения
Table applications {
  id uuid [pk, default: `gen_random_uuid()`]
  title varchar(100) [not null]
  description text
  image_url text

  is_active boolean [not null, default: true] // Типо активно, не активно приложение, чтоб не удалять его
  
  created_by_user_id uuid [not null, ref: > users.id]
  created_at timestamptz [not null, default: `now()`]
  updated_at timestamptz // Последнее изменения приложения, например изменил название
}

// Тарифы приложения (типо на 30 дней за 100р и тд...)
Table applications_plans {
  id uuid [pk, default: `gen_random_uuid()`]

  application_id uuid [not null, ref: > applications.id]

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


// Таблица ключей
Table keys {
  id uuid [pk, default: `gen_random_uuid()`]

  key_code varchar(255) [not null, unique]

  plan_id uuid [not null, ref: > applications_plans.id]

  status varchar(30) [not null, default: 'available']

  created_by_user_id uuid [ref: >? users.id]

  created_at timestamptz [not null, default: `now()`]

  indexes {
    (plan_id, status)
  }

  checks {
    `status IN ('available', 'reserved', 'sold', 'revoked')`
  }

}

// Таблица заказов
Table orders {
  id uuid [pk, default: `gen_random_uuid()`]

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

// Таблица платежей
Table payments {
  id uuid [pk, default: `gen_random_uuid()`]

  order_id uuid [not null, ref: > orders.id]

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

// Таблица для сохранения заказов
Table order_items {
  id uuid [pk, default: `gen_random_uuid()`]

  order_id uuid [not null, ref: > orders.id]
  plan_id uuid [not null, ref: > applications_plans.id]

  key_id uuid [unique, ref: -? keys.id]

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

// Таблица активаций ключей
Table activations {
  id uuid [pk, default: `gen_random_uuid()`]

  key_id uuid [not null, unique, ref: - keys.id]
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