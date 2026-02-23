INSERT INTO users (username, real_name, password, mail, account_created, `rank`, credits, pixels, points, ip_register, ip_current, machine_id)
VALUES ('admin', 'admin', 'admin', 'admin@localhost.com', UNIX_TIMESTAMP(), 7, 10000, 10000, 10000, '127.0.0.1', '127.0.0.1', '')
ON DUPLICATE KEY UPDATE
  real_name='admin',
  mail='admin@localhost.com',
  `rank`=7,
  credits=10000,
  pixels=10000,
  points=10000,
  ip_current='127.0.0.1';
