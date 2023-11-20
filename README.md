# Enjin Platform

Enjin Platform is the most powerful and advanced open-source framework for building NFT platforms. This repo aims in giving an out-of-box quick start solution to run an application with platform and the Efinity Wallet Daemon.

[![License: LGPL 3.0](https://img.shields.io/badge/license-LGPL_3.0-purple)](https://opensource.org/license/lgpl-3-0/)

## Quick start

1. If you haven't cloned the project yet, please clone it in any folder you want.
2. Now you can run our starter script `./start.sh` to start the application.

## Dependencies

Our repository already has all configurations files to run the application and its dependencies through docker. If you don't have docker installed follow the instructions at [Get Docker](https://docs.docker.com/get-docker/). You can check if it is installed by running:
```bash
docker -v
# Docker version 20.10.17, build 100c701
```

We also use docker compose, a tool for running multi-container Docker applications. Since April 22 it is already available with docker cli. You may check if you have it by running:

```bash
docker compose version
# Docker Compose version v2.6.0
```

With those installed you may proceed with the next step.

## Code documentation
Platform uses GraphQL which means it automatically generates documentation that can be accessed via the GraphQL IDEA. To access the IDE, simply navigate to `/graphiql` (noting the `i` in-between `graph` and `ql`).

Example:
```bash
http://localhost:8000/graphiql
```

## Changelog

Please see [CHANGELOG](CHANGELOG.md) for more information on what has changed recently.

## Contributing

Please see [CONTRIBUTING](.github/CONTRIBUTING.md) for details.

## Security Vulnerabilities

Please review [our security policy](../../security/policy) on how to report security vulnerabilities.

## Credits

- [Enjin](https://github.com/enjin)
- [All Contributors](../../contributors)

## License

The LGPL 3.0 License. Please see [License File](LICENSE) for more information.
