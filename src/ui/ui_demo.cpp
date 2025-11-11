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
