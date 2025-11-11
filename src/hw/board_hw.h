#pragma once
#include <Arduino.h>
#include "board_pins.h"

inline void hw_init_power_backlight() {
  pinMode(PIN_TFT_BL, OUTPUT);
  digitalWrite(PIN_TFT_BL, HIGH); // backlight ON (active HIGH)
}
inline void hw_init_led() {
  pinMode(PIN_LED_R, OUTPUT); pinMode(PIN_LED_G, OUTPUT); pinMode(PIN_LED_B, OUTPUT);
  digitalWrite(PIN_LED_R, HIGH); digitalWrite(PIN_LED_G, HIGH); digitalWrite(PIN_LED_B, HIGH); // off (common anode)
}
inline void hw_led_rgb(bool r_on, bool g_on, bool b_on) {
  digitalWrite(PIN_LED_R, r_on ? LOW : HIGH);
  digitalWrite(PIN_LED_G, g_on ? LOW : HIGH);
  digitalWrite(PIN_LED_B, b_on ? LOW : HIGH);
}
inline void hw_audio_enable(bool on) {
  pinMode(PIN_AUDIO_EN, OUTPUT);
  digitalWrite(PIN_AUDIO_EN, on ? LOW : HIGH); // LOW=enable
}
inline uint16_t hw_read_battery_raw() {
  return analogRead(PIN_BATT_ADC);
}
