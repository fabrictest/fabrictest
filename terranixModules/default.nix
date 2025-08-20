{
  imports = [
    ./migadu.nix
    ./tf.backend.nix
    ./tf.provider.cloudflare.nix
    ./tf.provider.migadu.nix
    ./tf.provider.random.nix
    ./tf.remote_state.nix
  ];
}
