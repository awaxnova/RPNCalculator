#ifndef LV_CONF_H
#define LV_CONF_H

#define LV_CONF_VERSION 92000

/* Display is 320x480, 16-bit color */
#define LV_COLOR_DEPTH 16
#define LV_HOR_RES_MAX 320
#define LV_VER_RES_MAX 480

/* We call lv_tick_inc(millis diff) ourselves */
#define LV_TICK_CUSTOM 1

/* Keep it lean; enable just a couple widgets */
#define LV_USE_LABEL 1
#define LV_USE_BTN 1

/* Logging off */
#define LV_USE_LOG 0

#endif /* LV_CONF_H */
