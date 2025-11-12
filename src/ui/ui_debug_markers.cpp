#include <lvgl.h>
#include <cstring>

// Tune these if you want bigger markers / different offsets
static const int MARKER_SIZE = 24;   // px
static const int MARKER_MARGIN = 12; // px from edges
static const int LABEL_GAP = 6;      // px between marker and its label

static lv_obj_t *make_marker(lv_obj_t *parent,
                             int x, int y,
                             lv_color_t color,
                             int radius, // 0=square, LV_RADIUS_CIRCLE=circle, or any px for rounded
                             const char *name_for_label)
{
    // Base marker (square/rounded/circle)
    lv_obj_t *m = lv_obj_create(parent);
    lv_obj_remove_style_all(m);
    lv_obj_set_size(m, MARKER_SIZE, MARKER_SIZE);
    lv_obj_set_style_bg_color(m, color, 0);
    lv_obj_set_style_bg_opa(m, LV_OPA_COVER, 0);
    lv_obj_set_style_radius(m, radius, 0);
    lv_obj_set_style_border_width(m, 2, 0);
    lv_obj_set_style_border_color(m, lv_color_black(), 0);
    lv_obj_set_pos(m, x, y);

    // Label with expected coords
    char buf[64];
    lv_snprintf(buf, sizeof(buf), "%s (%d,%d)", name_for_label, x, y);

    lv_obj_t *lab = lv_label_create(parent);
    lv_label_set_text(lab, buf);
    lv_obj_set_style_text_color(lab, lv_color_hex(0x404040), 0);

    // Place each label so it doesn’t overlap the marker
    // (simple rules based on corner)
    if (strcmp(name_for_label, "TL") == 0)
    {
        lv_obj_set_pos(lab, x + MARKER_SIZE + LABEL_GAP, y);
    }
    else if (strcmp(name_for_label, "TR") == 0)
    {
        lv_obj_set_pos(lab, x - LABEL_GAP - (int)lv_obj_get_width(lab), y);
    }
    else if (strcmp(name_for_label, "BR") == 0)
    {
        lv_obj_set_pos(lab, x - LABEL_GAP - (int)lv_obj_get_width(lab),
                       y - LABEL_GAP - (int)lv_obj_get_height(lab));
    }
    else if (strcmp(name_for_label, "BL") == 0)
    {
        lv_obj_set_pos(lab, x + MARKER_SIZE + LABEL_GAP,
                       y - LABEL_GAP - (int)lv_obj_get_height(lab));
    }
    else
    { // CENTER
        lv_obj_set_pos(lab, x + MARKER_SIZE + LABEL_GAP, y);
    }

    return m;
}

void draw_corner_markers()
{
    lv_obj_t *scr = lv_screen_active();
    lv_display_t *d = lv_display_get_default();
    int32_t W = lv_display_get_horizontal_resolution(d);
    int32_t H = lv_display_get_vertical_resolution(d);

    // Corner-ish coordinates (marker’s TOP-LEFT corner)
    int TLx = MARKER_MARGIN;
    int TLy = MARKER_MARGIN;

    int TRx = W - MARKER_MARGIN - MARKER_SIZE;
    int TRy = MARKER_MARGIN;

    int BRx = W - MARKER_MARGIN - MARKER_SIZE;
    int BRy = H - MARKER_MARGIN - MARKER_SIZE;

    int BLx = MARKER_MARGIN;
    int BLy = H - MARKER_MARGIN - MARKER_SIZE;

    int CX = (W - MARKER_SIZE) / 2;
    int CY = (H - MARKER_SIZE) / 2;

    // Shapes/colors:
    //  TL: red circle
    make_marker(scr, TLx, TLy, lv_color_hex(0xE53935), LV_RADIUS_CIRCLE, "TL");

    //  TR: green square
    make_marker(scr, TRx, TRy, lv_color_hex(0x43A047), 0, "TR");

    //  BR: blue rounded-rect
    make_marker(scr, BRx, BRy, lv_color_hex(0x1E88E5), 6, "BR");

    //  BL: orange circle
    make_marker(scr, BLx, BLy, lv_color_hex(0xFB8C00), LV_RADIUS_CIRCLE, "BL");

    //  C:  purple square (center)
    make_marker(scr, CX, CY, lv_color_hex(0x8E24AA), 0, "C");

    // Optional: print expected positions to log, too
    LV_LOG_USER("Markers (top-left corner of each): "
                "TL(%d,%d) TR(%d,%d) BR(%d,%d) BL(%d,%d) C(%d,%d)",
                TLx, TLy, TRx, TRy, BRx, BRy, BLx, BLy, CX, CY);
}
