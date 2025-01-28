@test "Flake show works" {
  run nix flake show
  [ "$status" -eq 0 ]
}

@test "Nix can build all containers" {
  run nix build '.#oci-all' --no-link
  [ "$status" -eq 0 ]
}

@test "Nix can run all check" {
  run nix flake check
  [ "$status" -eq 0 ]
}

# BUG check why bats broke container-structure-test
# @test "Nix run container-structure-test minimalistWithContainerStructureTest" {
#   env
#   run nix run '.#oci-container-structure-test-minimalistWithContainerStructureTest'
#   [ "$status" -eq 0 ]
# }

@test "Nix run cve grype minimalistWithGrype" {
  run nix run '.#oci-cve-grype-minimalistWithGrype'
  [ "$status" -eq 0 ]
}

@test "Nix run cve trivy minimalistWithTrivyIgnore" {
  run nix run '.#oci-cve-trivy-minimalistWithTrivyIgnore'
  [ "$status" -eq 0 ]
}

@test "Update pulled manifests locks works" {
  run nix run '.#oci-updatePulledManifestsLocks'
  [ "$status" -eq 0 ]
}

@test "Nix run sbom syft" {
  run nix run '.#oci-sbom-syft-minimalistWithSyft'
  [ "$status" -eq 0 ]
}

@test "Nix run credentials leaks trivy" {
  run nix run '.#oci-credentials-leak-minimalistWithCredentialsLeaksTrivy'
  [ "$status" -eq 0 ]
}
