#pragma once
#include "stack.h"
inline void op_add(RpnStack& st){ auto b=st.pop(), a=st.pop(); st.push(a+b); }
