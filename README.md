
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
