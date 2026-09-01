#ifndef DESKTOP_MULTI_WINDOW_WINDOWS_MANAGED_WINDOW_REMOVALS_H_
#define DESKTOP_MULTI_WINDOW_WINDOWS_MANAGED_WINDOW_REMOVALS_H_

#include <set>
#include <string>
#include <vector>

/// Collects managed Flutter windows that must be destroyed after the current
/// native window message has finished dispatching.
///
/// A FlutterWindow cannot remove its owning entry from MultiWindowManager in
/// OnDestroy: OnDestroy runs inside WM_DESTROY, so that would delete the
/// object while one of its methods is still executing. The application message
/// loop drains this queue immediately after DispatchMessage returns.
class ManagedWindowRemovals {
 public:
  void Schedule(const std::string& window_id) { pending_ids_.insert(window_id); }

  std::vector<std::string> TakePending() {
    std::vector<std::string> result(pending_ids_.begin(), pending_ids_.end());
    pending_ids_.clear();
    return result;
  }

  bool empty() const { return pending_ids_.empty(); }

 private:
  std::set<std::string> pending_ids_;
};

#endif  // DESKTOP_MULTI_WINDOW_WINDOWS_MANAGED_WINDOW_REMOVALS_H_
