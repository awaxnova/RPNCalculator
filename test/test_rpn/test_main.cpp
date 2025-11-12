#include <Arduino.h>
#include <unity.h>
#include "src/rpn/stack.h"
#include "src/rpn/ops.h"
void test_add(){ RpnStack st; st.push(1); st.push(2); op_add(st); TEST_ASSERT_EQUAL(1, st.size()); }
void setup(){ UNITY_BEGIN(); RUN_TEST(test_add); UNITY_END(); }
void loop(){}
