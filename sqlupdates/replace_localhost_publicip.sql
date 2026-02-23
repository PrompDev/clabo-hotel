UPDATE emulator_settings SET `value`='*' WHERE `key`='websockets.whitelist';
UPDATE website_settings SET `value` = REPLACE(`value`, '127.0.0.1', '167.179.172.168') WHERE `value` LIKE '%127.0.0.1%';
UPDATE website_settings SET `value` = REPLACE(`value`, 'localhost', '167.179.172.168') WHERE `value` LIKE '%localhost%';
UPDATE emulator_settings SET `value` = REPLACE(`value`, '127.0.0.1', '167.179.172.168') WHERE `value` LIKE '%127.0.0.1%';
UPDATE emulator_settings SET `value` = REPLACE(`value`, 'localhost', '167.179.172.168') WHERE `value` LIKE '%localhost%';
