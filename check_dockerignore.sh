#!/bin/sh

DOCKERFILE=""
BUILD_CONTEXT=""
DOCKERFILE_BACKUP=""

print_usage() {
  USAGE='usage: check_dockerignore.sh
    list-build-context [-f, --file Dockerfile] <build-context>
    git-ls-tree <build-context>
    check-dockerignore [-f, --file Dockerfile] <build-context>'
  >&2 printf "%s\n" "$USAGE"
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--file)
        # Check before we access $2
        if [ $# -le 1 ]; then
          print_usage
          exit 1
        fi
        DOCKERFILE="$2"
        shift
        shift
        ;;
      *)
        if [ -n "$BUILD_CONTEXT" ]; then
          print_usage
          exit 1
        fi
        BUILD_CONTEXT="$1"
        shift
        ;;
    esac
  done
  if [ -z "$BUILD_CONTEXT" ]; then
    print_usage
    exit 1
  fi
}

set_dockerfile_default_value() {
  if [ -z "$DOCKERFILE" ]; then
    build_context="$( (cd "$BUILD_CONTEXT" && pwd) )"
    DOCKERFILE="$build_context/Dockerfile"
  fi
}

check_docker() {
  if ! command -v docker 1>/dev/null 2>/dev/null; then
    >&2 printf "docker is not in PATH\n"
    exit 1
  fi
}

backup_dockerfile() {
  if ! [ -e "$DOCKERFILE" ]; then
    >&2 printf "dockerfile does not exist: %s\n" "$DOCKERFILE"
    exit 1
  fi
  DOCKERFILE_BACKUP=$(mktemp /tmp/check_dockerignore.XXXXXX)
  mv "$DOCKERFILE" "$DOCKERFILE_BACKUP"
}

replace_dockerfile() {
  cat <<EOF > "$DOCKERFILE"
FROM busybox
WORKDIR /build-context
COPY . .
CMD find . -type f | sort
EOF
}

build_image() {
  1>/dev/null 2>/dev/null docker build --pull --no-cache --file "$DOCKERFILE" --tag list-docker-build-context "$BUILD_CONTEXT"
}

print_build_context() {
  docker run --rm list-docker-build-context
}

remove_dockerfile() {
  rm "$DOCKERFILE"
}

restore_dockerfile() {
  if [ -e "$DOCKERFILE_BACKUP" ]; then
    mv "$DOCKERFILE_BACKUP" "$DOCKERFILE"
  fi
}

git_ls_tree() {
  # git ls-tree is working directory-aware, and it always prints the path without leading ./
  # So we take advantage of this behavior to use --format to always prepend ./ to match the output of find.
  (cd "$BUILD_CONTEXT" && git ls-tree HEAD -r --format "./%(path)" | sort)
}

list_build_context() {
  set_dockerfile_default_value
  check_docker
  backup_dockerfile
  replace_dockerfile
  build_image
  print_build_context
  remove_dockerfile
  restore_dockerfile
}

main() {
  if [ $# -eq 0 ]; then
    print_usage
    exit 1
  fi

  case "$1" in
    list-build-context)
      shift
      parse_args "$@"
      list_build_context
      ;;
    git-ls-tree)
      shift
      parse_args "$@"
      if [ -n "$DOCKERFILE" ]; then
        print_usage
        exit 1
      fi
      git_ls_tree
      ;;
    check-dockerignore)
      shift
      parse_args "$@"
      build_context_list=$(mktemp /tmp/check_dockerignore.XXXXXX)
      list_build_context >"$build_context_list"
      git_ls_tree_list=$(mktemp /tmp/check_dockerignore.XXXXXX)
      git_ls_tree >"$git_ls_tree_list"
      comm_list=$(mktemp /tmp/check_dockerignore.XXXXXX)
      comm -13 "$git_ls_tree_list" "$build_context_list" >"$comm_list"
      if [ -s "$comm_list" ]; then
        cat "$comm_list"
        exit 1
      fi
      ;;
    *)
      print_usage
      exit 1
      ;;
  esac
}

main "$@"
