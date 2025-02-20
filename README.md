# Stacks

Cloud native stacks for application development.

## Local Development

```shell
# Clone the repo or just do `git pull`
git clone git@github.com:h8r-dev/stacks.git

# Watch files and develop
make watch
```

## Run test

Each stack has its own test suite.
See [gin-vue test](./gin-vue/test/README.md) for example.

## Documentation

- [Stack documentation](https://heighliner.dev/docs/core_features/stacks/overview)
- Use [remote buildkit](https://heighliner.dev/docs/development/buildkit)

## Repo Structure

This repo provides the following CUE modules:

- The entire repo can be imported as a CUE module.
- Each stack can be imported as a CUE module.
- The cuelib can be imported as a CUE module.

This repo contains the following stacks:

- [sample](./sample/)
- [gin-vue](./gin-vue/)
- [gin-next](./gin-next/)