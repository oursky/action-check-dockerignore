# action-check-dockerignore

## Overview

This repository contains a shell script [check_dockerignore.sh](./check_dockerignore.sh) that checks .dockerignore against .gitignore.
In other words, the ignored files by your .dockerignore should be a super set of the ignored files by your .gitignore.
The purpose of it is to prevent unintended files from being sent to the build context.

Apart from the shell script, a GitHub action is defined [action.yml](./action.yml). That means you can easily integrate the checking with GitHub Actions. See below for details.

## Using this in GitHub Actions

If you build a Docker image at your project root, you can refer to this configuration.

```yaml
steps:
- uses: actions/checkout@v4
- uses: oursky/action-check-dockerignore@v1
  with:
    build-context: .
```

If you build a Docker image at your project root, but with a custom Dockerfile, you can refer to this configuration.

```yaml
steps:
- uses: actions/checkout@v4
- uses: oursky/action-check-dockerignore@v1
  with:
    build-context: .
    dockerfile: Dockerfile-custom
```

If your .dockerignore file is correct, this GitHub action does not output anything.
If your .dockerignore file is incorrect, this GitHub action prints out a list of files that should be ignored in .dockerignore.
You can review the list and amend your .dockerignore file to correct the problem.

## Using this locally

When you are fixing your .dockerignore file, you may consider downloading the shell script and run it locally to iterate faster.

```sh
curl https://raw.githubusercontent.com/oursky/action-check-dockerignore/main/check_dockerignore.sh > ./check_dockerignore.sh
chmod u+x ./check_dockerignore.sh
# Run it with build-context = .
./check_dockerignore.sh check-dockerignore .
```
