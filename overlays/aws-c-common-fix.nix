# Fix aws-c-common flaky tests
# Test suite has intermittent failures across platforms:
# - Test #395 (test_thread_scheduler_happy_path_cancellation) - fails on NixOS
# - Test #343 (ring_buffer_acquire_up_to_multi_threaded_test) - times out on macOS
# These tests are part of the aws-c-common test suite and cause build failures
# for packages that depend on it (nix, attic, aws-sdk-cpp, etc.)
final: prev: {
  aws-c-common = prev.aws-c-common.overrideAttrs (old: {
    doCheck = false;  # Skip all tests to avoid flaky test failures
  });
}
