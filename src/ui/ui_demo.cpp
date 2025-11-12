#include <lvgl.h>
#include "ui_debug_markers.h"

static const char *kDefaultText = "Hello, RPN! v2";
static lv_timer_t *s_restore_timer = NULL;

static void restore_label_cb(lv_timer_t *t)
{
  lv_obj_t *label = (lv_obj_t *)lv_timer_get_user_data(t);
  lv_label_set_text(label, kDefaultText);
  lv_timer_delete(t); // one-shot
  s_restore_timer = NULL;
}

static void btn_event_cb(lv_event_t *e)
{
  if (lv_event_get_code(e) == LV_EVENT_CLICKED)
  {
    lv_obj_t *label = (lv_obj_t *)lv_event_get_user_data(e);
    lv_label_set_text(label, "Pressed!");

    if (s_restore_timer)
    {
      lv_timer_reset(s_restore_timer); // extend the deadline
    }
    else
    {
      s_restore_timer = lv_timer_create(restore_label_cb, 2000, label);
    }
  }
}

void ui_demo_create()
{
  lv_obj_t *label = lv_label_create(lv_screen_active());
  lv_label_set_text(label, kDefaultText);
  lv_obj_align(label, LV_ALIGN_TOP_MID, 0, 20);

  lv_obj_t *btn = lv_btn_create(lv_screen_active());
  lv_obj_align(btn, LV_ALIGN_CENTER, 0, 0);

  lv_obj_t *blabel = lv_label_create(btn);
  lv_label_set_text(blabel, "Tap me");
  lv_obj_center(blabel);

  lv_obj_add_event_cb(btn, btn_event_cb, LV_EVENT_CLICKED, label);

  draw_corner_markers();
}
