# Overlay to fix buildEnv pathsToLinkJSON bug
final: prev: {
  buildEnv = args:
    let
      # Ensure pathsToLink is always a list
      fixedArgs = args // {
        pathsToLink =
          if builtins.isString (args.pathsToLink or null)
          then [ args.pathsToLink ]
          else (args.pathsToLink or [ "/" ]);
      };
    in
    prev.buildEnv fixedArgs;
}
