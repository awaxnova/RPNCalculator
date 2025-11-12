#include <Arduino.h>
#include <lvgl.h>
#include <TFT_eSPI.h>
#include "ui_demo.h"
#include "../hw/board_pins.h"

static TFT_eSPI tft;       // uses build_flags pin defs
static lv_display_t *disp; // LVGL display
static lv_indev_t *touchscreen;

static const uint32_t screenWidth = 320;
static const uint32_t screenHeight = 480;
static lv_color_t *buf1 = nullptr; // draw buffer

/* LVGL tick */
static uint32_t last_ms = 0;

static void disp_flush_cb(lv_display_t *d, const lv_area_t *area, unsigned char *px_map)
{
  // Convert LVGL color map to TFT
  uint32_t w = area->x2 - area->x1 + 1;
  uint32_t h = area->y2 - area->y1 + 1;
  tft.startWrite();
  tft.setAddrWindow(area->x1, area->y1, w, h);
  tft.pushPixels((uint16_t *)px_map, w * h);
  tft.endWrite();
  lv_display_flush_ready(d);
}

// REPLACE your touch_read_cb with this:
static void touch_read_cb(lv_indev_t *indev, lv_indev_data_t *data)
{
  uint16_t x, y;
  // Optional: adjust threshold (default 600). Example: 600 here.
  bool touched = tft.getTouch(&x, &y, 600);
  if (touched)
  {
    data->state = LV_INDEV_STATE_PRESSED;
    data->point.x = x;
    data->point.y = y;
  }
  else
  {
    data->state = LV_INDEV_STATE_RELEASED;
  }
}

void ui_init()
{
  lv_init();

  tft.init();
  tft.setRotation(1); // 1: 320x480 portrait? Adjust if needed: try 1 or 3 for landscape
  tft.fillScreen(TFT_BLACK);
  tft.setSwapBytes(true); // for pushImage if used
  pinMode(PIN_TOUCH_IRQ, INPUT);

  // Allocate a 1/10 screen buffer (saves RAM); LVGL double-buffers internally
  size_t buf_pixels = (screenWidth * screenHeight) / 10;
  buf1 = (lv_color_t *)heap_caps_malloc(buf_pixels * sizeof(lv_color_t), MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
  if (!buf1)
    buf1 = (lv_color_t *)malloc(buf_pixels * sizeof(lv_color_t));

  disp = lv_display_create(screenWidth, screenHeight);
  lv_display_set_flush_cb(disp, disp_flush_cb);
  lv_display_set_buffers(disp, buf1, nullptr, buf_pixels * sizeof(lv_color_t), LV_DISPLAY_RENDER_MODE_PARTIAL);

  // Touch
  lv_indev_t *indev = lv_indev_create();
  touchscreen = indev;
  lv_indev_set_type(indev, LV_INDEV_TYPE_POINTER);
  lv_indev_set_read_cb(indev, touch_read_cb);

  // Demo UI
  ui_demo_create();
}

void ui_loop()
{
  // Ticks
  uint32_t now = millis();
  uint32_t diff = now - last_ms;
  last_ms = now;
  lv_tick_inc(diff ? diff : 1);
  lv_timer_handler();
}
