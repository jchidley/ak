#!/usr/bin/env bats

setup() {
  export TEST_REPO="$BATS_TEST_TMPDIR/repo"
  export TEST_BIN="$BATS_TEST_TMPDIR/fake-bin"
  export INSTALL_BIN="$BATS_TEST_TMPDIR/install-bin"
  mkdir -p "$TEST_REPO/bin" "$TEST_REPO/services" "$TEST_REPO/secrets" "$TEST_BIN" "$INSTALL_BIN"
  cp "$BATS_TEST_DIRNAME/../bin/ak" "$TEST_REPO/bin/ak"
  chmod +x "$TEST_REPO/bin/ak"

  cat >"$TEST_REPO/services/test.yaml" <<'YAML'
name: "Test service"
env_var: TEST_KEY
url: "https://example.invalid/keys"
notes: |
  Test fixture only.
YAML

  cat >"$TEST_REPO/services/private.yaml" <<'YAML'
name: "Non-exportable credential"
env_var: PRIVATE_CREDENTIAL
export: false
YAML

  printf 'TEST-KEY-ID\n' >"$TEST_REPO/.gpg-key-id"

  cat >"$TEST_BIN/gpg" <<'SH'
#!/bin/bash
set -e
if [[ " $* " == *" --decrypt "* ]]; then
  printf '%s' "$(<"${!#}")"
  exit 0
fi
if [[ " $* " == *" --encrypt "* ]]; then
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--output" ]]; then
      output="$2"
      break
    fi
    shift
  done
  [[ -n "${output:-}" ]]
  cat >"$output"
  exit 0
fi
echo "unexpected fake gpg invocation" >&2
exit 2
SH
  chmod +x "$TEST_BIN/gpg"
  ln -s "$TEST_REPO/bin/ak" "$INSTALL_BIN/ak"
}

@test "installed symlink resolves the canonical repository without AK_DIR" {
  printf 'fixture-secret' >"$TEST_REPO/secrets/test.gpg"

  run env -u AK_DIR PATH="$TEST_BIN:$PATH" "$INSTALL_BIN/ak" get test

  [ "$status" -eq 0 ]
  [ "$output" = "fixture-secret" ]
}

@test "list reports service metadata without decrypting values" {
  printf 'fixture-secret' >"$TEST_REPO/secrets/test.gpg"

  run env AK_DIR="$TEST_REPO" PATH="$TEST_BIN:$PATH" "$TEST_REPO/bin/ak" list

  [ "$status" -eq 0 ]
  [[ "$output" == *"test"* ]]
  [[ "$output" == *"TEST_KEY"* ]]
  [[ "$output" != *"fixture-secret"* ]]
}

@test "set succeeds when there is no legacy age file" {
  run bash -c 'printf "%s\n" "new-secret" | env AK_DIR="$1" PATH="$2:$PATH" "$1/bin/ak" set test' _ "$TEST_REPO" "$TEST_BIN"

  [ "$status" -eq 0 ]
  [ "$(<"$TEST_REPO/secrets/test.gpg")" = "new-secret" ]
}

@test "export shell-quotes secrets instead of executing their contents" {
  marker="$BATS_TEST_TMPDIR/injected"
  secret="abc'def \$(touch $marker)"
  printf '%s' "$secret" >"$TEST_REPO/secrets/test.gpg"

  run env AK_DIR="$TEST_REPO" PATH="$TEST_BIN:$PATH" "$TEST_REPO/bin/ak" export test
  [ "$status" -eq 0 ]
  export_line="$output"

  run bash -c 'eval "$1"; printf "%s" "$TEST_KEY"' _ "$export_line"
  [ "$status" -eq 0 ]
  [ "$output" = "$secret" ]
  [ ! -e "$marker" ]
}

@test "bulk export excludes credentials marked export false" {
  printf 'api-secret' >"$TEST_REPO/secrets/test.gpg"
  printf 'private-secret' >"$TEST_REPO/secrets/private.gpg"

  run env AK_DIR="$TEST_REPO" PATH="$TEST_BIN:$PATH" "$TEST_REPO/bin/ak" export

  [ "$status" -eq 0 ]
  [[ "$output" == *"TEST_KEY"* ]]
  [[ "$output" != *"PRIVATE_CREDENTIAL"* ]]
  [[ "$output" != *"private-secret"* ]]
}

@test "explicit export rejects credentials marked export false" {
  printf 'private-secret' >"$TEST_REPO/secrets/private.gpg"

  run env AK_DIR="$TEST_REPO" PATH="$TEST_BIN:$PATH" "$TEST_REPO/bin/ak" export private

  [ "$status" -ne 0 ]
  [[ "$output" == *"not exportable"* ]]
  [[ "$output" != *"private-secret"* ]]
}
