<#  bootstrap-pio-repo.ps1  (LVGL + TFT_eSPI + your pinout)
    Usage:
      .\bootstrap-pio-repo.ps1 -ProjectName "rpn-calc-fw" -InitGit
      .\bootstrap-pio-repo.ps1 -Force
#>

param(
  [string]$ProjectName = (Split-Path -Leaf (Get-Location)),
  [switch]$InitGit,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

function New-DirIfMissing([string]$path) {
  if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path | Out-Null }
}
function Write-File([string]$path, [string]$content) {
  if ((Test-Path $path) -and -not $Force) { Write-Host "SKIP (exists): $path"; return }
  $dir = Split-Path $path; if ($dir) { New-DirIfMissing $dir }
  $content | Out-File -FilePath $path -Encoding utf8 -Force
  Write-Host "Wrote: $path"
}

# --- Folders ---
@(
  '.github/workflows','.vscode','include','lib','src/ui','src/rpn','src/hw',
  'test/test_rpn','data','scripts','partitions'
) | ForEach-Object { New-DirIfMissing $_ }

# --- .gitignore ---
Write-File ".gitignore" @'
.pio/
.vscode/.browse.VC.db*
.vscode/ipch
.vscode/c_cpp_properties.json
.DS_Store
*.pyc
data/.cache/
include/secrets.h
'@

# --- README ---
Write-File "README.md" @'

# $ProjectName

ESP32-32E + 4.0\" ST7796S (320x480) + resistive touch (XPT2046-style), LVGL UI.

## Quick start
1) Install VS Code + PlatformIO extension  
2) USB-C connect board  
3) Build/Upload/Monitor:
\`\`\`
pio run -e esp32_debug
pio run -e esp32_debug -t upload
pio device monitor -b 115200
\`\`\`
'@

# --- LICENSE placeholder ---
Write-File "LICENSE" "MIT (placeholder)."

# --- VS Code ---
Write-File ".vscode/extensions.json" @'
{ "recommendations": ["platformio.platformio-ide","ms-vscode.cpptools","ms-vscode.cmake-tools"] }
'@
Write-File ".vscode/settings.json" @'
{
  "editor.formatOnSave": true,
  "files.associations": { "*.inc": "cpp" },
  "C_Cpp.default.configurationProvider": "platformio.platformio-ide",
  "terminal.integrated.defaultProfile.windows": "PowerShell"
}
'@
Write-File ".vscode/launch.json" @'
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Open Serial Monitor",
      "type": "cppdbg",
      "request": "launch",
      "program": "${command:platformio-ide.upload}",
      "preLaunchTask": "PlatformIO: Monitor",
      "miDebuggerPath": ""
    }
  ]
}
'@

# --- CI ---
Write-File ".github/workflows/ci.yml" @'
name: build
on: [push, pull_request]
jobs:
  pio-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - name: Install PlatformIO
        run: pip install platformio
      - name: Build (debug)
        run: pio run -e esp32_debug
      - name: Build (release)
        run: pio run -e esp32_release
'@

# --- PlatformIO (Arduino + LVGL + TFT_eSPI) ---
Write-File "platformio.ini" @'
[platformio]
default_envs = esp32_debug
description = ESP32-32E + ST7796S(320x480) + XPT2046 touch + LVGL

[env]
platform = espressif32@6.6.0
framework = arduino
board = esp32dev
board_build.flash_mode = qio
board_build.filesystem = littlefs
monitor_speed = 115200
upload_speed = 921600

lib_deps =
  bodmer/TFT_eSPI @ ^2.5.43
  lvgl/lvgl @ ^9.2.0
  bblanchon/ArduinoJson @ ^7.1.0

; Generate version header
extra_scripts = scripts/version_header.py

; Custom partition (app + FS)
board_build.partitions = partitions/app_fs_4MB.csv

; ==== Display/Touch Wiring (your board) ====
; LCD on HSPI: MOSI=13, MISO=12, SCLK=14, CS=15, DC=2, RST tied to EN (-1), BL=27
; Touch XPT2046: CS=33, IRQ=36 (on same SPI)
; SD (VSPI default): CS=5 (CLK=18, MOSI=23, MISO=19)
build_flags =
  -D SERIAL_BAUD=115200
  -D CORE_DEBUG_LEVEL=1
  -D USER_SETUP_LOADED
  -D ST7796_DRIVER
  -D TFT_RGB_ORDER=0
  -D TFT_BACKLIGHT_ON=HIGH
  -D TFT_SPI_PORT=HSPI
  -D SPI_FREQUENCY=40000000
  -D SPI_READ_FREQUENCY=16000000
  -D SPI_TOUCH_FREQUENCY=2500000
  -D TFT_MOSI=13
  -D TFT_MISO=12
  -D TFT_SCLK=14
  -D TFT_CS=15
  -D TFT_DC=2
  -D TFT_RST=-1
  -D TFT_BL=27
  -D TOUCH_CS=33
  -D TOUCH_IRQ=36
  -D SD_CS=5

[env:esp32_debug]
build_type = debug
build_flags =
  ${env.build_flags}
  -D BUILD_FLAVOR_DEBUG
  -Og -g3 -fno-inline

[env:esp32_release]
build_type = release
build_flags =
  ${env.build_flags}
  -D BUILD_FLAVOR_RELEASE
  -O2
'@

# --- Partitions ---
Write-File "partitions/app_fs_4MB.csv" @'
# Name,   Type, SubType, Offset,  Size,   Flags
nvs,      data, nvs,     0x9000,  0x5000,
otadata,  data, ota,     0xE000,  0x2000,
app0,     app,  ota_0,   0x10000, 0x280000,
spiffs,   data, spiffs,  0x290000,0x170000,
'@

# --- Version header script ---
Write-File "scripts/version_header.py" @'
import os, subprocess, datetime
from pathlib import Path

def git(cmd):
    try: return subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL).decode().strip()
    except Exception: return "nogit"

root = Path(os.getcwd()); (root/"include").mkdir(exist_ok=True)
ver = git("git describe --tags --always")
branch = git("git rev-parse --abbrev-ref HEAD")
dt = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
(root/"include"/"version_auto.h").write_text(
    f"#pragma once\n#define FW_VERSION \"{ver}\"\n#define FW_BRANCH \"{branch}\"\n#define FW_BUILD_UTC \"{dt}\"\n",
    encoding="utf-8"
)
'@

# --- LVGL config (minimal, v9) ---
Write-File "include/lv_conf.h" @'
#ifndef LV_CONF_H
#define LV_CONF_H

#define LV_CONF_VERSION 92000
#define LV_USE_OS 0
#define LV_COLOR_DEPTH 16
#define LV_COLOR_16_SWAP 0
#define LV_TICK_CUSTOM 1
#define LV_DPI_DEF 150

#define LV_USE_LOG 0
#define LV_USE_ASSERT_NULL 0
#define LV_USE_ASSERT_MALLOC 0

#define LV_DRAW_SW_COMPLETE 1

/* Display size */
#define LV_HOR_RES_MAX 320
#define LV_VER_RES_MAX 480

/* Drivers */
#define LV_USE_TIMER 1
#define LV_USE_EVENT 1
#define LV_USE_LABEL 1
#define LV_USE_BTN   1

#endif /* LV_CONF_H */
'@

# --- Pins / board helpers ---
Write-File "src/hw/board_pins.h" @'
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
'@

Write-File "src/hw/board_hw.h" @'
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
'@

# --- LVGL port (TFT_eSPI + touch) ---
Write-File "src/ui/lvgl_port.h" @'
#pragma once
void ui_init();
void ui_loop();
'@

Write-File "src/ui/lvgl_port.cpp" @'
#include <Arduino.h>
#include <lvgl.h>
#include <TFT_eSPI.h>
#include "ui_demo.h"
#include "../hw/board_pins.h"

static TFT_eSPI tft;           // uses build_flags pin defs
static lv_display_t* disp;     // LVGL display
static lv_indev_t* touchscreen;

static const uint32_t screenWidth  = 320;
static const uint32_t screenHeight = 480;
static lv_color_t *buf1 = nullptr; // draw buffer

/* LVGL tick */
static uint32_t last_ms = 0;

static void disp_flush_cb(lv_display_t *d, const lv_area_t *area, unsigned char *px_map) {
  // Convert LVGL color map to TFT
  uint32_t w = area->x2 - area->x1 + 1;
  uint32_t h = area->y2 - area->y1 + 1;
  tft.startWrite();
  tft.setAddrWindow(area->x1, area->y1, w, h);
  tft.pushPixels((uint16_t*)px_map, w * h);
  tft.endWrite();
  lv_display_flush_ready(d);
}

static void touch_read_cb(lv_indev_t * indev, lv_indev_data_t * data) {
  uint16_t x, y; uint16_t z = 0;
  bool touched = tft.getTouch(&x, &y, &z);
  if (touched) {
    data->state = LV_INDEV_STATE_PRESSED;
    data->point.x = x;
    data->point.y = y;
  } else {
    data->state = LV_INDEV_STATE_RELEASED;
  }
}

void ui_init() {
  lv_init();

  tft.init();
  tft.setRotation(1); // 1: 320x480 portrait? Adjust if needed: try 1 or 3 for landscape
  tft.fillScreen(TFT_BLACK);
  tft.setSwapBytes(true); // for pushImage if used
  pinMode(PIN_TOUCH_IRQ, INPUT);

  // Allocate a 1/10 screen buffer (saves RAM); LVGL double-buffers internally
  size_t buf_pixels = (screenWidth * screenHeight) / 10;
  buf1 = (lv_color_t*)heap_caps_malloc(buf_pixels * sizeof(lv_color_t), MALLOC_CAP_INTERNAL | MALLOC_CAP_8BIT);
  if (!buf1) buf1 = (lv_color_t*)malloc(buf_pixels * sizeof(lv_color_t));

  disp = lv_display_create(screenWidth, screenHeight);
  lv_display_set_flush_cb(disp, disp_flush_cb);
  lv_display_set_buffers(disp, buf1, nullptr, buf_pixels * sizeof(lv_color_t), LV_DISPLAY_RENDER_MODE_PARTIAL);

  // Touch
  tft.setTouch(PIN_TOUCH_CS, PIN_TOUCH_IRQ);
  lv_indev_t* indev = lv_indev_create();
  touchscreen = indev;
  lv_indev_set_type(indev, LV_INDEV_TYPE_POINTER);
  lv_indev_set_read_cb(indev, touch_read_cb);

  // Demo UI
  ui_demo_create();
}

void ui_loop() {
  // Ticks
  uint32_t now = millis();
  uint32_t diff = now - last_ms;
  last_ms = now;
  lv_tick_inc(diff ? diff : 1);
  lv_timer_handler();
}
'@

# --- Simple UI demo (LVGL label + button) ---
Write-File "src/ui/ui_demo.h" @'
#pragma once
void ui_demo_create();
'@
Write-File "src/ui/ui_demo.cpp" @'
#include <lvgl.h>

static void btn_event_cb(lv_event_t * e) {
  lv_obj_t * label = (lv_obj_t*)lv_event_get_user_data(e);
  lv_label_set_text(label, "Pressed!");
}

void ui_demo_create() {
  lv_obj_t * label = lv_label_create(lv_screen_active());
  lv_label_set_text(label, "Hello, RPN!");
  lv_obj_align(label, LV_ALIGN_TOP_MID, 0, 20);

  lv_obj_t * btn = lv_btn_create(lv_screen_active());
  lv_obj_align(btn, LV_ALIGN_CENTER, 0, 0);
  lv_obj_t * blabel = lv_label_create(btn);
  lv_label_set_text(blabel, "Tap me");
  lv_obj_center(blabel);

  lv_obj_add_event_cb(btn, btn_event_cb, LV_EVENT_CLICKED, label);
}
'@

# --- App config / main ---
Write-File "include/app_config.h" @'
#pragma once
#include "version_auto.h"
#ifndef SERIAL_BAUD
#define SERIAL_BAUD 115200
#endif
'@

Write-File "src/main.cpp" @'
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
'@

# --- RPN stubs + test ---
Write-File "src/rpn/stack.h" @'
#pragma once
#include <vector>
class RpnStack {
 public:
  void push(double v){ s_.push_back(v); }
  double pop(){ double v = s_.back(); s_.pop_back(); return v; }
  size_t size() const { return s_.size(); }
 private: std::vector<double> s_;
};
'@
Write-File "src/rpn/ops.h" @'
#pragma once
#include "stack.h"
inline void op_add(RpnStack& st){ auto b=st.pop(), a=st.pop(); st.push(a+b); }
'@
Write-File "test/test_rpn/test_main.cpp" @'
#include <Arduino.h>
#include <unity.h>
#include "src/rpn/stack.h"
#include "src/rpn/ops.h"
void test_add(){ RpnStack st; st.push(1); st.push(2); op_add(st); TEST_ASSERT_EQUAL(1, st.size()); }
void setup(){ UNITY_BEGIN(); RUN_TEST(test_add); UNITY_END(); }
void loop(){}
'@

# --- data/lib placeholders ---
Write-File "data/README.md" "Place LittleFS assets here (fonts, themes, JSON)."
Write-File "lib/README.md" "Local reusable libraries live here."

# --- Partitions already done above ---

# --- Optional git init ---
if ($InitGit) {
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Warning "git not found; skipping git init."
  } else {
    if (-not (Test-Path ".git")) {
      git init | Out-Null
      git add . | Out-Null
      git commit -m "chore: scaffold PlatformIO repo (LVGL + TFT_eSPI + board pinout)" | Out-Null
      Write-Host "Initialized git repo and made first commit."
    } else {
      Write-Host ".git exists; skipping init."
    }
  }
}

Write-Host "`nDone. Next:"
Write-Host "  code ."
Write-Host "  pio run -e esp32_debug -t upload"
Write-Host "  pio device monitor -b 115200"
