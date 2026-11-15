-- Permisos efectivos utilizados por el middleware central de autorización.
INSERT INTO permissions (code, description) VALUES
  ('account.access', 'Acceso autenticado a funciones de cuenta'),
  ('partner.access', 'Acceso exclusivo a funciones del rol socio'),
  ('payment_request.create', 'Crear y consultar solicitudes de pago propias'),
  ('owned_content.manage', 'Gestionar contenido y recursos propios'),
  ('administration.manage', 'Gestionar moderación y administración general'),
  ('authorization.manage', 'Gestionar permisos y autorización')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role, permission_id)
SELECT grants.role::user_role, p.id
FROM (
  VALUES
    ('user', 'account.access'),
    ('user', 'payment_request.create'),
    ('partner', 'account.access'),
    ('partner', 'partner.access'),
    ('partner', 'payment_request.create'),
    ('partner', 'owned_content.manage'),
    ('admin', 'account.access'),
    ('admin', 'owned_content.manage'),
    ('admin', 'administration.manage'),
    ('master', 'account.access'),
    ('master', 'owned_content.manage'),
    ('master', 'administration.manage'),
    ('master', 'authorization.manage')
) AS grants(role, permission_code)
JOIN permissions p ON p.code = grants.permission_code
ON CONFLICT (role, permission_id) DO NOTHING;
