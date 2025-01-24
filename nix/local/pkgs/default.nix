inputs.nixpkgs.appendOverlays [
  (self: super: super.prefer-remote-fetch self super)
]
