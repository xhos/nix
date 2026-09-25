{inputs, ...}: {
  imports = [ (inputs.import-tree [./core ./opt]) ];
}
