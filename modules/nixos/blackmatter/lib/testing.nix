# Module testing framework for blackmatter components
{ lib, config, pkgs ? null, ... }:
with lib;
rec {
  # Test result type
  testResult = {
    name = mkOption {
      type = types.str;
      description = "Test name";
    };
    
    passed = mkOption {
      type = types.bool;
      description = "Whether test passed";
    };
    
    message = mkOption {
      type = types.str;
      default = "";
      description = "Test result message";
    };
    
    duration = mkOption {
      type = types.nullOr types.float;
      default = null;
      description = "Test execution time in seconds";
    };
  };
  
  # Test suite type
  testSuite = {
    name = mkOption {
      type = types.str;
      description = "Test suite name";
    };
    
    tests = mkOption {
      type = types.listOf (types.submodule { options = testResult; });
      description = "List of test results";
    };
    
    passed = mkOption {
      type = types.bool;
      description = "Whether all tests in suite passed";
    };
    
    summary = mkOption {
      type = types.str;
      description = "Test suite summary";
    };
  };
  
  # Create a test assertion
  mkTest = name: assertion: message:
    {
      inherit name message;
      passed = assertion;
    };
  
  # Create a test that checks if an attribute exists
  mkExistsTest = name: attrPath: value:
    mkTest name 
      (hasAttrByPath (splitString "." attrPath) value)
      "Attribute ${attrPath} should exist";
  
  # Create a test that checks attribute equality
  mkEqualTest = name: expected: actual:
    mkTest name
      (expected == actual)
      "Expected: ${toString expected}, Actual: ${toString actual}";
  
  # Create a test that checks list contains element
  mkContainsTest = name: element: list:
    mkTest name
      (elem element list)
      "List should contain ${toString element}";
  
  # Create a test that validates type
  mkTypeTest = name: expectedType: value:
    let
      actualType = builtins.typeOf value;
    in mkTest name
      (actualType == expectedType)
      "Expected type: ${expectedType}, Actual: ${actualType}";
  
  # Run a test suite
  runTestSuite = name: tests:
    let
      results = tests;
      allPassed = all (test: test.passed) results;
      passCount = length (filter (test: test.passed) results);
      totalCount = length results;
      summary = "${toString passCount}/${toString totalCount} tests passed";
    in {
      inherit name results;
      passed = allPassed;
      inherit summary;
    };
  
  # Module configuration tester
  moduleTests = {
    # Test basic module structure
    testModuleStructure = module:
      let
        hasOptions = module ? options;
        hasConfig = module ? config;
        hasImports = module ? imports || true; # imports are optional
      in runTestSuite "Module Structure" [
        (mkTest "has-options" hasOptions "Module should have options")
        (mkTest "has-config" hasConfig "Module should have config")
      ];
    
    # Test enable option pattern
    testEnableOption = modulePath: config:
      let
        enablePath = modulePath ++ ["enable"];
        hasEnable = hasAttrByPath enablePath config;
        enableValue = getAttrFromPath enablePath config;
        isBoolean = builtins.typeOf enableValue == "bool";
      in runTestSuite "Enable Option" [
        (mkTest "has-enable" hasEnable "Module should have enable option")
        (mkTest "enable-is-bool" isBoolean "Enable option should be boolean")
      ];
    
    # Test microservice base patterns
    testMicroserviceBase = service: cfg:
      let
        hasPort = cfg ? port;
        hasDataDir = cfg ? dataDir;
        hasMode = cfg ? mode;
        portValid = hasPort -> (cfg.port >= 1024 && cfg.port <= 65535);
        modeValid = hasMode -> (elem cfg.mode ["dev" "prod"]);
      in runTestSuite "Microservice Base" [
        (mkTest "has-port" hasPort "Service should have port option")
        (mkTest "port-valid" portValid "Port should be in valid range")
        (mkTest "has-mode" hasMode "Service should have mode option")
        (mkTest "mode-valid" modeValid "Mode should be dev or prod")
      ];
    
    # Test service dependencies
    testServiceDependencies = service: dependencies:
      let
        hasService = dependencies.serviceDependencies ? ${service};
        serviceConfig = dependencies.serviceDependencies.${service} or {};
        hasProvides = serviceConfig ? provides;
        hasRequires = serviceConfig ? requires;
        providesValid = hasProvides -> (builtins.typeOf serviceConfig.provides == "list");
        requiresValid = hasRequires -> (builtins.typeOf serviceConfig.requires == "list");
      in runTestSuite "Service Dependencies" [
        (mkTest "service-exists" hasService "Service should exist in dependencies")
        (mkTest "has-provides" hasProvides "Service should have provides list")
        (mkTest "has-requires" hasRequires "Service should have requires list")
        (mkTest "provides-valid" providesValid "Provides should be a list")
        (mkTest "requires-valid" requiresValid "Requires should be a list")
      ];
  };
  
  # Validation tests
  validationTests = {
    # Test port uniqueness validation
    testPortValidation = services:
      let
        ports = flatten (mapAttrsToList (name: cfg: 
          if cfg.enable or false && cfg ? port then 
            [{ service = name; port = cfg.port; }] 
          else []
        ) services);
        
        duplicatePorts = filter (p1: 
          length (filter (p2: p1.port == p2.port && p1.service != p2.service) ports) > 0
        ) ports;
        
        noDuplicates = duplicatePorts == [];
      in runTestSuite "Port Validation" [
        (mkTest "no-duplicate-ports" noDuplicates 
          "No duplicate ports: ${concatStringsSep ", " (map (p: "${p.service}:${toString p.port}") duplicatePorts)}")
      ];
    
    # Test domain validation
    testDomainValidation = services:
      let
        domains = flatten (mapAttrsToList (name: cfg:
          if cfg.enable or false && cfg ? domain then
            [{ service = name; domain = cfg.domain; }]
          else []
        ) services);
        
        validDomains = filter (d: 
          builtins.match "^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$" d.domain != null
        ) domains;
        
        allValid = length validDomains == length domains;
      in runTestSuite "Domain Validation" [
        (mkTest "domains-valid" allValid "All domains should be valid format")
      ];
  };
  
  # Integration tests
  integrationTests = {
    # Test service startup order
    testStartupOrder = enabledServices: dependencies:
      let
        validation = dependencies.validateServiceConfig { 
          blackmatter.components.microservices = enabledServices;
        };
        hasOrder = validation.startupOrder != [];
        orderValid = validation.valid;
      in runTestSuite "Startup Order" [
        (mkTest "has-startup-order" hasOrder "Should generate startup order")
        (mkTest "order-valid" orderValid "Startup order should be valid")
      ];
    
    # Test dependency resolution
    testDependencyResolution = service: enabledServices: dependencies:
      let
        resolved = dependencies.resolveDependencies service enabledServices;
        hasService = resolved ? service;
        hasRequires = resolved ? requires;
        hasAfter = resolved ? after;
      in runTestSuite "Dependency Resolution" [
        (mkTest "has-service" hasService "Should resolve service")
        (mkTest "has-requires" hasRequires "Should have requires list")
        (mkTest "has-after" hasAfter "Should have after list")
      ];
  };
  
  # Performance tests
  performanceTests = {
    # Test module evaluation time
    testEvaluationTime = module: threshold:
      let
        start = builtins.currentTime;
        result = module;
        end = builtins.currentTime;
        duration = end - start;
        withinThreshold = duration <= threshold;
      in runTestSuite "Performance" [
        (mkTest "evaluation-time" withinThreshold 
          "Module evaluation should complete within ${toString threshold}s (took ${toString duration}s)")
      ];
  };
  
  # Test runner utilities
  testUtils = {
    # Run all tests for a module
    runModuleTests = moduleName: module: config:
      let
        moduleConfig = getAttrFromPath (splitString "." moduleName) config;
        structureTests = moduleTests.testModuleStructure module;
        enableTests = moduleTests.testEnableOption (splitString "." moduleName) config;
        allTests = [structureTests enableTests];
        allPassed = all (suite: suite.passed) allTests;
      in {
        inherit moduleName allTests;
        passed = allPassed;
        summary = "Module ${moduleName}: ${if allPassed then "PASS" else "FAIL"}";
      };
    
    # Run all tests for microservices
    runMicroserviceTests = services: dependencies:
      let
        serviceNames = attrNames services;
        serviceTests = map (name:
          let
            cfg = services.${name};
            baseTests = moduleTests.testMicroserviceBase name cfg;
            depTests = moduleTests.testServiceDependencies name dependencies;
          in runTestSuite "Service ${name}" [baseTests depTests]
        ) serviceNames;
        
        validationTests = [
          validationTests.testPortValidation services
          validationTests.testDomainValidation services
        ];
        
        allTests = serviceTests ++ validationTests;
        allPassed = all (suite: suite.passed) allTests;
      in {
        inherit allTests;
        passed = allPassed;
        summary = "Microservices: ${if allPassed then "PASS" else "FAIL"}";
      };
    
    # Generate test report
    generateReport = testSuites:
      let
        totalSuites = length testSuites;
        passedSuites = length (filter (suite: suite.passed) testSuites);
        totalTests = foldl' (acc: suite: acc + length suite.tests) 0 testSuites;
        passedTests = foldl' (acc: suite: 
          acc + length (filter (test: test.passed) suite.tests)
        ) 0 testSuites;
        
        suiteResults = map (suite: 
          "  ${suite.name}: ${if suite.passed then "PASS" else "FAIL"} (${suite.summary})"
        ) testSuites;
        
        failedTests = flatten (map (suite:
          if !suite.passed then
            map (test: "    ${suite.name}:${test.name} - ${test.message}") 
              (filter (test: !test.passed) suite.tests)
          else []
        ) testSuites);
      in ''
        # Test Report
        
        ## Summary
        - Test Suites: ${toString passedSuites}/${toString totalSuites} passed
        - Individual Tests: ${toString passedTests}/${toString totalTests} passed
        - Overall Status: ${if passedSuites == totalSuites then "PASS" else "FAIL"}
        
        ## Test Suite Results
        ${concatStringsSep "\n" suiteResults}
        
        ${optionalString (failedTests != []) ''
        ## Failed Tests
        ${concatStringsSep "\n" failedTests}
        ''}
      '';
  };
  
  # Export main testing interface
  mkTestSuite = runTestSuite;
  runTests = testUtils.runModuleTests;
  runAllTests = testUtils.runMicroserviceTests;
  generateTestReport = testUtils.generateReport;
}