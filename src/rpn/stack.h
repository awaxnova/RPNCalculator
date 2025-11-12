#pragma once
#include <vector>
class RpnStack {
 public:
  void push(double v){ s_.push_back(v); }
  double pop(){ double v = s_.back(); s_.pop_back(); return v; }
  size_t size() const { return s_.size(); }
 private: std::vector<double> s_;
};
