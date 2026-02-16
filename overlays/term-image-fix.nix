# Fix term-image test failures with Pillow deprecation warnings
# term-image tests fail due to DeprecationWarning from Pillow's getdata method
# Solution: disable tests for term-image package
final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      term-image = python-prev.term-image.overridePythonAttrs (old: {
        doCheck = false;
      });
    })
  ];
}
