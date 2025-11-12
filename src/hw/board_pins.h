#pragma once
// LCD
#define PIN_TFT_CS   15
#define PIN_TFT_DC    2
#define PIN_TFT_RST  -1   // tied to EN (shared reset)
#define PIN_TFT_BL   27
// Touch
#define PIN_TOUCH_CS 33
#define PIN_TOUCH_IRQ 36
// SD
#define PIN_SD_CS     5
// RGB LED (common anode, active-LOW)
#define PIN_LED_R    22
#define PIN_LED_G    16
#define PIN_LED_B    17
// Audio (amp enable LOW, DAC on IO26)
#define PIN_AUDIO_EN  4
#define PIN_AUDIO_DAC 26
// Battery ADC
#define PIN_BATT_ADC 34
