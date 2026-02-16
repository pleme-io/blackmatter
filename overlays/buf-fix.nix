# Fix buf flaky tests
# Test suite has timeout issues in testLintWithOptions (takes >2m50s)
# The tests are functional tests that are slow and flaky, not critical for functionality
final: prev: {
  buf = prev.buf.overrideAttrs (old: {
    doCheck = false;  # Skip tests to avoid long-running test timeouts
  });
}
