UPDATE emulator_settings SET `value`='*' WHERE `key`='websockets.whitelist';
UPDATE website_settings SET `value` = 'http://167.179.172.168:8080/api/imager/?figure=' WHERE `key` = 'avatar_imager';
UPDATE website_settings SET `value` = 'http://167.179.172.168:8080/swf/c_images/album1584' WHERE `key` = 'badges_path';
UPDATE website_settings SET `value` = 'http://167.179.172.168:8080/usercontent/badgeparts/generated' WHERE `key` = 'group_badge_path';
UPDATE website_settings SET `value` = 'http://167.179.172.168:8080/swf/dcr/hof_furni' WHERE `key` = 'furniture_icons_path';
UPDATE website_settings SET `value` = 'http://167.179.172.168:3000' WHERE `key` = 'nitro_path';
