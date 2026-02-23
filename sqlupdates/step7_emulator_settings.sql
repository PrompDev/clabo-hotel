UPDATE emulator_settings SET `value`='http://127.0.0.1:8080/usercontent/camera/' WHERE `key`='camera.url';
UPDATE emulator_settings SET `value`='/app/assets/usercontent/camera/' WHERE `key`='imager.location.output.camera';
UPDATE emulator_settings SET `value`='/app/assets/usercontent/camera/thumbnail/' WHERE `key`='imager.location.output.thumbnail';
UPDATE emulator_settings SET `value`='http://127.0.0.1:8080/api/imageproxy/0x0/http://img.youtube.com/vi/%video%/default.jpg' WHERE `key`='imager.url.youtube';
UPDATE emulator_settings SET `value`='0' WHERE `key`='console.mode';
UPDATE emulator_settings SET `value`='/app/assets/usercontent/badgeparts/generated/' WHERE `key`='imager.location.output.badges';
UPDATE emulator_settings SET `value`='/app/assets/swf/c_images/Badgeparts' WHERE `key`='imager.location.badgeparts';
