#include <Arduino.h>
#include "app_config.h"
#include "hw/board_hw.h"
#include "ui/lvgl_port.h"

void setup() {
  Serial.begin(SERIAL_BAUD);
  delay(100);
  Serial.println("\n[FW] booting...");

  hw_init_power_backlight();
  hw_init_led();
  hw_led_rgb(true,false,false); // red ON briefly

  ui_init();

  hw_led_rgb(false,true,false); // green ON (ready)
}

void loop() {
  ui_loop();
  delay(5);
}
