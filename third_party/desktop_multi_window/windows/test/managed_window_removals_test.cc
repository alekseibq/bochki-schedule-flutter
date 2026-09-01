#include "managed_window_removals.h"

#include <iostream>
#include <string>
#include <vector>

namespace {

bool Expect(bool condition, const char* message) {
  if (condition) return true;
  std::cerr << "Expectation failed: " << message << std::endl;
  return false;
}

}  // namespace

int main() {
  ManagedWindowRemovals removals;

  removals.Schedule("procedure-session");
  removals.Schedule("procedure-session");
  removals.Schedule("workday-editor");

  if (!Expect(!removals.empty(), "scheduled removals must be retained")) {
    return 1;
  }

  const auto pending = removals.TakePending();
  if (!Expect(pending == std::vector<std::string>{"procedure-session",
                                                   "workday-editor"},
              "duplicate closes must produce one removal per window")) {
    return 1;
  }
  if (!Expect(removals.empty(), "draining removals must clear the queue")) {
    return 1;
  }
  if (!Expect(removals.TakePending().empty(),
              "a second drain must not repeat a removal")) {
    return 1;
  }

  return 0;
}
